
local s = {}

function s.serialize_orig(o)
  local str = "";
  if type(o) == "number" then
    str = tostring(o);
  elseif type(o) == "string" then
    str = string.format("%q",o);
  elseif type(o) == "table" then
    str = "{";
    for k,v in pairs(o) do
      str = str..string.format("[%s]=%s,",serialize_orig(k),serialize_orig(v));
    end
    str = str.."}";
  else
    str = "nil";
  end
  return str;
end

--New serialization code omiting integer indexes for tables
--Only do recursive call if v is a table
-- Pack size 2.3X smaller, Serilization time 3.4X faster on OP
function s.serialize(o)
  local str = "";
  if type(o) == "number" then
    if o%1==0 then --quickest check for integer
      str=tostring(o);
    else
      str = string.format("%.2f",o);--2-digit precision
    end
  elseif type(o) == "string" then
    str = string.format("%q",o);
  elseif type(o) == "table" then
    str = "{";
    local is_num=true;
    for k,v in pairs(o) do
      if type(k)=="string" then
        if type(v) == "number" then
	  if v%1==0 then --quickest check for integer
            str = str..string.format("[%q]=%d,",k,v);
    	  else
	    str = str..string.format("[%q]=%.2f,",k,v);
	  end
	elseif type(v)=="string" then
          str = str..string.format("[%q]=%q,",k,v);
	elseif type(v)=="table" then
          str = str..string.format("[%q]=%s,",k, s.serialize(v));
	end
      else
        if type(v) == "number" then
	  if v%1==0 then --quickest check for integer
            str = str..string.format("%d,",v);
    	  else
	    str = str..string.format("%.2f,",v);
	  end
	elseif type(v)=="string" then
          str = str..string.format("%q,",v);
	elseif type(v)=="table" then
          str = str..string.format("%s,", s.serialize(v));
	end
      end

    end
    str = str.."}";
  else
    str = "nil";
  end
  return str;
end
function s.deserialize(s)
  --local x = assert(loadstring("return "..s))();
  if not s then
    return '';
  end
  -- protected loadstring call
  ok, ret = pcall(loadstring('return '..s));
  --local x = loadstring("return "..s)();
  if not ok then
    --print(string.format("Warning: Could not deserialize message:\n%s",s));
    return '';
  else
    return ret;
  end
end

return s
