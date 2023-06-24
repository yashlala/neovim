local helpers = require('test.functional.helpers')(after_each)
local clear, nvim, eq = helpers.clear, helpers.nvim, helpers.eq
local command = helpers.command -- TODO: actually use this
local next_msg = helpers.next_msg

describe('autocmd TabMoved', function()
  before_each(clear)

  describe('with * as <amatch>', function()
    -- We should also be able to trigger this event via mouse movements. I'm not sure how to do
    -- that. TODO(yashlala): add mouse tests.
    it('matches when moving any tab via :tabmove', function()
      nvim('command', 'au! TabMoved * echom "tabmoved:".expand("<afile>").":".expand("<amatch>").":".tabpagenr()')
      repeat
        nvim('command', 'tabnew')
      until nvim('eval', 'tabpagenr()') == 3 -- current tab is now 3
      eq("tabmoved:1:1:1", nvim('exec', 'tabmove 0', true)) -- move after 0, current tab is now 1
      nvim('command', 'tabnext 2') -- move to the second tab
      eq("tabmoved:3:3:3", nvim('exec', 'tabmove $', true)) -- move tab to end, current tab is now 3
      eq("tabmoved:2:2:2", nvim('exec', 'tabmove -1', true)) -- move tab 1 down, current tab is now 2
    end)

    it('does not trigger when a tab is moved to the same page number', function()
      nvim('command', 'au! TabMoved * echom "tabmoved:".expand("<afile>").":".expand("<amatch>").":".tabpagenr()')
      repeat
        nvim('command', 'tabnew')
      until nvim('eval', 'tabpagenr()') == 3 -- current tab is now 3
      nvim('command', 'tabmove $')
      -- TODO(yashlala): Is there a better way to detect "no input" than via timeout?
      eq(nil, next_msg(200))
    end)

    it('is not triggered when tabs are created or closed', function()
      nvim('command', 'au! TabMoved * echom "tabmoved:".expand("<afile>").":".expand("<amatch>").":".tabpagenr()')
      nvim('command', 'file Xtestfile1')
      nvim('command', '0tabedit Xtestfile2')
      nvim('command', 'tabclose')
      eq(nil, next_msg(200))
    end)
  end)

  describe('with NR as <amatch>', function()
    it('matches when closing a tab whose index is NR', function()
      nvim('command', 'au! TabMoved * echom "tabmoved:".expand("<afile>").":".expand("<amatch>").":".tabpagenr()')
      nvim('command', 'au! TabMoved 2 echom "tabmoved:match"')
      repeat
        nvim('command',  'tabnew')
      until nvim('eval', 'tabpagenr()') == 4 -- current tab is now 4
      -- sanity check, we shouldn't match on target page numbers != 2
      eq("tabmoved:1:1:1", nvim('exec', 'tabmove 0', true)) -- current tab is now 1
      nvim('command', '3tabnext')
      eq("tabmoved:2:2:2\ntabmoved:match", nvim('exec', 'tabmove 1', true))
    end)
  end)
end)

