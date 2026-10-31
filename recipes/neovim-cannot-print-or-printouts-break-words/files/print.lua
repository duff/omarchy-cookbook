-- Prints the current buffer with lp. lp's text filter breaks long lines at
-- the last column, mid-word, so lines are wrapped here first: at a space,
-- with the continuation indented like the line it came from (under the text
-- of a list item).
local M = {}

-- Characters across a printed line. The filter prints 10 to the inch, so
-- Letter paper with quarter-inch margins fits 80, and A4 about 77.
local width = 80

local function expand_tabs(line, tabstop)
  if not line:find("\t") then
    return line
  end
  local out, col = {}, 0
  for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
    local n = ch == "\t" and tabstop - col % tabstop or 1
    out[#out + 1] = ch == "\t" and string.rep(" ", n) or ch
    col = col + n
  end
  return table.concat(out)
end

local function wrap(line, out)
  local lead = line:match("^%s*[-*+]%s+") or line:match("^%s*%d+[.)]%s+") or line:match("^%s*")
  local hang = #lead <= width / 2 and string.rep(" ", vim.fn.strchars(lead)) or ""
  local rest = line
  while vim.fn.strchars(rest) > width do
    local head = vim.fn.strcharpart(rest, 0, width + 1)
    -- The last space with words before it, not one in the indent.
    local keep = head:match("^(.*%S)%s")
    if not keep or #keep <= #(rest:match("^%s*[-*+]%s+") or rest:match("^%s*")) then
      keep = vim.fn.strcharpart(rest, 0, width)
    end
    out[#out + 1] = keep
    local remaining = rest:sub(#keep + 1):gsub("^%s+", "")
    if remaining == "" then
      return
    end
    rest = hang .. remaining
  end
  out[#out + 1] = rest
end

function M.buffer()
  local lines = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    wrap(expand_tabs(line, vim.bo.tabstop), lines)
  end
  local out = vim.trim(vim.fn.system({ "lp", "-t", vim.fn.expand("%:t") }, lines))
  vim.notify(out, vim.v.shell_error == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
end

return M
