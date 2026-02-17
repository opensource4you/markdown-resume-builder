-- resume-filter.lua
function Pandoc(doc)
  local blocks = doc.blocks
  local new_blocks = {}
  local i = 1

  while i <= #blocks do
    local el = blocks[i]
    
    -- Detection logic: Header (.experience-block) followed by Div (.metadata)
    if el.t == "Header" and el.classes:includes("experience-block") and
       i < #blocks and blocks[i+1].t == "Div" and blocks[i+1].classes:includes("metadata") then
      
      local header = el
      local metadata_div = blocks[i+1]
      
      if FORMAT:match 'latex' then
        -- 1. Extract title content
        local title_content = pandoc.write(pandoc.Pandoc({pandoc.Plain(header.content)}), 'latex')
        title_content = title_content:gsub("\n", "")

        -- 2. Extract metadata
        local date = ""
        local subtitle = ""
        local location = ""

        pandoc.walk_block(metadata_div, {
          Span = function(span)
            if span.classes:includes("date") then
              date = pandoc.write(pandoc.Pandoc({pandoc.Plain(span.content)}), 'latex'):gsub("\n", "")
            elseif span.classes:includes("subtitle") then
              subtitle = pandoc.write(pandoc.Pandoc({pandoc.Plain(span.content)}), 'latex'):gsub("\n", "")
            elseif span.classes:includes("location") then
              location = pandoc.write(pandoc.Pandoc({pandoc.Plain(span.content)}), 'latex'):gsub("\n", "")
            end
          end
        })

        -- 3. Combine LaTeX
        -- Use {\large\bfseries ...} to make the Title bigger than Header 4
        -- NOTE: modify vspace here to control the distance between bullet point and title
        local latex_code = string.format(
          "\\noindent {\\large\\bfseries %s} \\hfill %s \\\\ \n %s \\hfill \\textit{%s} \\vspace{-1mm}", 
          title_content, date, subtitle, location
        )

        table.insert(new_blocks, pandoc.RawBlock('latex', latex_code))
        
        -- Skip the next block (metadata div)
        i = i + 1
      else
        -- Keep HTML as is
        table.insert(new_blocks, el)
      end
    else
      -- Keep regular blocks
      table.insert(new_blocks, el)
    end
    i = i + 1
  end
  
  return pandoc.Pandoc(new_blocks, doc.meta)
end
