local M = {}

local uv = vim.uv or vim.loop
local state_file = vim.fn.stdpath("state") .. "/clangd-builds.json"

M._defaults = {}
M._commands_created = false

local function normalize(path)
  if not path or path == "" then
    return nil
  end

  local absolute = vim.fn.fnamemodify(path, ":p"):gsub("/+$", "")
  return vim.fs.normalize(absolute)
end

local function is_file(path)
  local stat = path and uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

local function load_state()
  if vim.fn.filereadable(state_file) ~= 1 then
    return {}
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_file), "\n"))
  if not ok or type(decoded) ~= "table" then
    return {}
  end

  return decoded
end

local function save_selection(root, directory)
  local state = load_state()
  state[root] = directory

  local ok, result = pcall(function()
    vim.fn.mkdir(vim.fs.dirname(state_file), "p")
    return vim.fn.writefile({ vim.json.encode(state) }, state_file)
  end)

  if not ok or result ~= 0 then
    vim.notify("無法儲存 clangd build 選擇：" .. state_file, vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.project_root(start)
  start = normalize(start or vim.api.nvim_buf_get_name(0) or vim.fn.getcwd())
  if not start then
    return normalize(vim.fn.getcwd())
  end

  local stat = uv.fs_stat(start)
  if not stat or stat.type ~= "directory" then
    start = vim.fs.dirname(start)
  end

  local marker = vim.fs.find(".git", { path = start, upward = true })[1]
  return marker and normalize(vim.fs.dirname(marker)) or normalize(vim.fn.getcwd())
end

function M.candidates(root)
  root = normalize(root or M.project_root())
  if not root then
    return {}
  end

  local files = vim.fn.globpath(root .. "/build", "*/compile_commands.json", false, true)
  local candidates = {}

  for _, file in ipairs(files) do
    local stat = uv.fs_stat(file)
    if stat and stat.type == "file" then
      local directory = normalize(vim.fs.dirname(file))
      candidates[#candidates + 1] = {
        name = vim.fs.basename(directory),
        directory = directory,
        mtime = stat.mtime.sec,
      }
    end
  end

  table.sort(candidates, function(a, b)
    if a.mtime == b.mtime then
      return a.name < b.name
    end
    return a.mtime > b.mtime
  end)

  if candidates[1] then
    candidates[1].latest = true
  end

  return candidates
end

function M.selected(root)
  root = normalize(root or M.project_root())
  if not root then
    return nil, nil
  end

  local saved = normalize(load_state()[root])
  if saved and is_file(saved .. "/compile_commands.json") then
    return saved, "remembered"
  end

  local default = normalize(M._defaults[root])
  if default and is_file(default .. "/compile_commands.json") then
    return default, "default"
  end

  local candidates = M.candidates(root)
  if #candidates == 1 then
    return candidates[1].directory, "only"
  end

  return nil, nil
end

function M.clangd_cmd(base, root)
  local command = {}
  for _, argument in ipairs(base or { "clangd" }) do
    if not argument:match("^%-%-compile%-commands%-dir=") then
      command[#command + 1] = argument
    end
  end

  local directory = M.selected(root)
  if directory then
    command[#command + 1] = "--compile-commands-dir=" .. directory
  end

  return command
end

local function apply_selection(root, directory)
  root = normalize(root)
  directory = normalize(directory)
  if not root or not is_file(directory .. "/compile_commands.json") then
    vim.notify("找不到 compilation database：" .. tostring(directory), vim.log.levels.ERROR)
    return
  end

  save_selection(root, directory)

  local config = vim.lsp.config.clangd
  if config then
    vim.lsp.config("clangd", {
      cmd = M.clangd_cmd(config.cmd, root),
    })
  end

  local relative = vim.fs.relpath(root, directory) or directory
  if config and vim.fn.exists(":LspRestart") == 2 then
    vim.cmd("LspRestart! clangd")
    vim.notify("clangd 已切換至 " .. relative .. "，正在重新索引")
  else
    vim.notify("clangd 已記住 " .. relative .. "，下次啟動時套用")
  end
end

function M.select(root)
  root = normalize(root or M.project_root())
  local candidates = M.candidates(root)
  if #candidates == 0 then
    vim.notify("在 " .. root .. "/build/* 找不到 compile_commands.json", vim.log.levels.WARN)
    return
  end

  local active = M.selected(root)
  table.sort(candidates, function(a, b)
    local a_active = a.directory == active
    local b_active = b.directory == active
    if a_active ~= b_active then
      return a_active
    end
    if a.mtime == b.mtime then
      return a.name < b.name
    end
    return a.mtime > b.mtime
  end)

  vim.ui.select(candidates, {
    prompt = string.format("clangd build directory（共 %d 個）", #candidates),
    format_item = function(item)
      local tags = {}
      if item.directory == active then
        tags[#tags + 1] = "目前"
      end
      if item.latest then
        tags[#tags + 1] = "最新"
      end
      local tag = #tags > 0 and (" [" .. table.concat(tags, "/") .. "]") or ""
      return string.format("build/%s%s  %s", item.name, tag, os.date("%Y-%m-%d %H:%M", item.mtime))
    end,
  }, function(choice)
    if choice then
      apply_selection(root, choice.directory)
    end
  end)
end

function M.latest(root)
  root = normalize(root or M.project_root())
  local candidates = M.candidates(root)
  if #candidates == 0 then
    vim.notify("在 " .. root .. "/build/* 找不到 compile_commands.json", vim.log.levels.WARN)
    return
  end
  apply_selection(root, candidates[1].directory)
end

function M.info(root)
  root = normalize(root or M.project_root())
  local directory, source = M.selected(root)
  if not directory then
    vim.notify("clangd 尚未選擇 build；執行 :ClangdBuildSelect")
    return
  end

  local relative = vim.fs.relpath(root, directory) or directory
  vim.notify(string.format("clangd build：%s（%s）", relative, source))
end

function M.setup(opts)
  opts = opts or {}
  for root, directory in pairs(opts.defaults or {}) do
    M._defaults[normalize(root)] = normalize(directory)
  end

  if M._commands_created then
    return
  end
  M._commands_created = true

  vim.api.nvim_create_user_command("ClangdBuildSelect", function()
    M.select()
  end, { desc = "選擇並記住 clangd compilation database" })

  vim.api.nvim_create_user_command("ClangdBuildLatest", function()
    M.latest()
  end, { desc = "切換至最近更新的 clangd compilation database" })

  vim.api.nvim_create_user_command("ClangdBuildInfo", function()
    M.info()
  end, { desc = "顯示 clangd 目前使用的 compilation database" })
end

return M
