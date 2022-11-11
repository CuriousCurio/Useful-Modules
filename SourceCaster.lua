-- This module formats datatypes into initializers for use in source code. Datatypes will be changed into neat string initializers

local encode_types:{} = require(script.Parent.EncodeTypes);

local module = {};
function module:Encode(v:any)
	return encode_types:Encode(v);
end
return module;
