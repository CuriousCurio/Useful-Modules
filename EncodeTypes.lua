local number_i = 'number';

local tween = TweenInfo.new();
local tween_params = {'Time', 'EasingStyle', 'EasingDirection', 'DelayTime', 'Reverses', 'RepeatCount'};
local natural_string = '^[_a-zA-Z][_a-zA-Z0-9]+';
local table_item_pattern = '%s = %s,\n	';

local patterns = {
	Rect = 'Rect.new(%s, %s, %s, %s)',
	Region3 = 'Region3.new(%s, %s)',
	Vector2int16 = 'Vector2int16.new(%s, %s)',
	Vector2 = 'Vector2.new(%s, %s)',
	Vector3int16 = 'Vector3int16.new(%s, %s, %s)',
	Vector3 = 'Vector3.new(%s, %s, %s)',
	Color3 = 'Color3.new(%s, %s, %s)',
	ColorSequenceKeypoint = 'ColorSequenceKeypoint.new(%s, %s)',
	ColorSequence = 'ColorSequence.new(%s, %s)',
	NumberSequenceKeypoint = 'NumberSequenceKeypoint.new(%s, %s)',
	NumberSequence = 'NumberSequence.new(%s, %s)',
	Enum = 'Enum.%s',
	EnumItem = 'Enum.%s.%s',
	UDim = 'UDim.new(%s, %s)',
	UDim2 = 'UDim2.new(%s, %s, %s, %s)',
	UDim2_Offset = 'UDim2.fromOffset(%s, %s)',
	UDim2_Scale = 'UDim2.fromScale(%s, %s)',
	CFrame = 'CFrame.new(%s, %s, %s)',
	CFrame_Angles = 'CFrame.Angles(%s, %s, %s)',
	PhysicalProperties_1 = 'PhysicalProperties.new(%s)',
	PhysicalProperties_3 = 'PhysicalProperties.new(%s, %s, %s)',
	PhysicalProperties_5 = 'PhysicalProperties.new(%s, %s, %s, %s, %s)',
	TweenInfo = 'TweenInfo.new(%s)'
}

local function MergePi(n) -- Checks if the number is equal to divisor or products of pi
	if (n == math.pi) then return 'math.pi'; end

	for i = .75,.25,-.25 do -- If n is a divisor (.75, .5, .25), or (2/3, 1/2, 1/3)
		if (n == (math.pi * i)) then
			return 'math.pi * ' .. tostring(i);
		end
	end
	for i = 2,4,1 do -- If n is a product (2, 3, 4)
		if (n == (math.pi * i)) then
			return 'math.pi * ' .. tostring(i);
		end
	end
end
local function NumberToString(n) -- Converts a number into a clean floating string
	if (math.floor(n) == n) then return tostring(n); end

	local str = string.format('%.6f', n);
	local str_clip = string.gsub(str, '0+$', '');

	if (#str ~= #str_clip) then return str_clip; end
	return str;
end
local function MergeHuge(n) -- Checks if the number is equal to inf, if so it will use the math.huge math property
	if (n == math.huge) then return 'math.huge'; end
end
local function Number(n)
	return MergeHuge(n) or MergePi(n) or NumberToString(n);
end

return {
	Encode = function(self, v)
		local ToString = self[typeof(v)];
		if (ToString) then return ToString(self, v); end
		return self[v];
	end,

	params = function(self, table)
		local str = '(' do
			for _,v in ipairs(table) do
				str = str .. self:Encode(v) .. ', ';
			end
			str = str:sub(0,-3); -- Removing end
		end;
		return str .. ')';
	end,
	table = function(self, table)
		local str = '{' do
			for i,v in next,table do
				v = self:Encode(v);
				if (type(i) == number_i) then str = str .. v; continue;; end -- If the index is a number, just put it in as-is
				i = '[' .. self:Encode(i) .. ']';
				str = str .. string.format(table_item_pattern, i, v);
			end
			str = str:sub(0,-5); -- Removing end
		end;
		return str .. '\n}';
	end,
	string = function(self, v)return '"'..v..'"' end,
	number = function(self, v:number)return Number(v)end,
	boolean = function(self, v)return tostring(v); end,
	Rect = function(self, v)		return string.format(patterns.Rect, v.Min.X, v.Min.Y, v.Max.X, v.Max.Y) 		end,
	Region3 = function(self, v)		 return string.format(patterns.Region3, self:Vector3(v.Min), self:Vector3(v.Max)) 		end,
	Vector2int16 = function(self, v)		return string.format(patterns.Vector2int16, Number(v.X), Number(v.Y)) 		end,
	Vector2 = function(self, v)		return string.format(patterns.Vector2, Number(v.X), Number(v.Y)) 		end,
	Vector3int16 = function(self, v)		return string.format(patterns.Vector3int16, Number(v.X), Number(v.Y), Number(v.Z)) 		end,
	Vector3 = function(self, v)		return string.format(patterns.Vector3, Number(v.X), Number(v.Y), Number(v.Z)) 		end,
	Color3 = function(self, v)		return string.format(patterns.Color3, Number(v.X), Number(v.Y), Number(v.Z)) 		end,
	ColorSequenceKeypoint = function(self, v)		return string.format(patterns.ColorSequenceKeypoint, Number(v.Time), self:Color3(v.Value)) 		end,
	ColorSequence = function(self, v)
		local keypoints = v.Keypoints;
		local k1,k2 = keypoints[1], keypoints[2];
		if (k1.Time == 0 and k2.Time == 1) then return string.format(patterns.ColorSequence, self:Color3(k1.Value), self:Color3(k2.Value)); end -- First and last only
		for i = 1,#keypoints do
			keypoints[i] = self:ColorSequenceKeypoint(keypoints[i]); -- Changing keypoints to strings, then return initializer
		end
		return 'ColorSequence.new' .. self:table(keypoints);
	end,
	NumberSequenceKeypoint = function(self, v)return string.format(patterns.NumberSequenceKeypoint, Number(v.Time), Number(v.Value)) end,
	NumberSequence = function(self, v)
		local keypoints = v.Keypoints;
		local k1,k2 = keypoints[1], keypoints[2];
		if (k1.Time == 0 and k2.Time == 1) then return string.format(patterns.NumberSequence, Number(k1.Value), Number(k2.Value)); end -- First and last only
		for i = 1,#keypoints do
			keypoints[i] = self:NumberSequenceKeypoint(keypoints[i]); -- Changing keypoints to strings, then return initializer
		end
		return 'NumberSequence.new' .. self:table(keypoints);
	end,
	Enum = function(self, v)return string.format(patterns.Enum, tostring(v)) end,
	EnumItem = function(self, v)return string.format('%s.%s', self:Enum(v.EnumType), v.Name) end,
	UDim = function(self, v)
		if (v.Scale == 0 and v.Offset == 0) then return 'UDIm.new()'; end
		return string.format(patterns.UDim, v.Scale, v.Offset);
	end,
	UDim2 = function(self, v)
		local x, y = v.X, v.Y;
		local scl_ = x.Scale == 0 and y.Scale == 0;
		local off_ = x.Offset == 0 and y.Offset == 0;

		if (scl_ and off_) then return 'UDim2.new()'; end
		if (scl_) then return string.format(patterns.UDim2_Offset, Number(x.Offset), Number(y.Offset)); end -- fromOffset
		if (off_) then return string.format(patterns.UDim2_Scale, Number(x.Scale), Number(y.Scale)); end	 -- fromScale
		return string.format(patterns.UDim2, Number(x.Scale), Number(x.Offset), Number(y.Scale), Number(y.Offset));
	end,
	CFrame = function(self, v)
		local str = string.format(patterns.CFrame, Number(v.X), Number(v.Y), Number(v.Z));
		local x, y, z = v:ToEulerAnglesYXZ();
		if (x ~= 0 or y ~= 0 or z ~= 0) then -- If the CFrame has angles
			str = str .. string.format(' * '..patterns.CFrame_Angles, Number(x), Number(y), Number(z));
		end
		return str;
	end,
	PhysicalProperties = function(self, v)
		local params do
			for _,enum_item in ipairs(Enum.Material:GetEnumItems()) do -- Checking if matching material enum item
				if (v == PhysicalProperties.new(enum_item)) then
					params = {self:EnumItem(enum_item)};
					break;
				end
			end

			if (params == nil) then -- If not material
				params = {Number(v.Density), Number(v.Friction), Number(v.Elasticity)};

				if (v.FrictionWeight ~= 1 or v.ElasticityWeight ~= 1) then -- If both FrictionWeight and ElasticityWeight are native values
					table.insert(params, Number(v.FrictionWeight));
					table.insert(params, Number(v.ElasticityWeight));
				end
			end
		end;
		return 'PhysicalProperties.new' .. self:params(params);
	end,
	TweenInfo = function(self, v)
		local params = {} do
			for ni = 6,1,-1 do -- Iterates backwards, if a property isn't the same as the initialized one, grab all of the properties before it as strings
				local i = tween_params[ni];
				if (v[i] ~= tween[i]) then
					for ni = 1,ni do
						params[ni] = v[tween_params[ni]];
					end
				end
			end
		end;
		return 'TweenInfo.new' .. self:params(params);
	end,
	[Axes] = 'Axes', [BrickColor] = 'BrickColor', [CatalogSearchParams] = 'CatalogSearchParams', [CFrame] = 'CFrame',
	[Color3] = 'Color3', [ColorSequence] = 'ColorSequence', [ColorSequenceKeypoint] = 'ColorSequenceKeypoint', [DateTime] = 'DateTime',
	[DockWidgetPluginGuiInfo] = 'DockWidgetPluginGuiInfo', [Enum] = 'Enum', [Faces] = 'Faces', [NumberRange] = 'NumberRange',
	[NumberSequence] = 'NumberSequence', [NumberSequenceKeypoint] = 'NumberSequenceKeypoint', [PathWaypoint] = 'PathWaypoint', [PhysicalProperties] = 'PhysicalProperties',
	[Random] = 'Random', [Ray] = 'Ray', [Instance] = 'Instance', [RaycastParams] = 'RaycastParams',
	[Rect] = 'Rect', [Region3] = 'Region3', [Region3int16] = 'Region3int16', [string] = 'string',
	[table] = 'table', [TweenInfo] = 'TweenInfo', [UDim] = 'UDim', [UDim2] = 'UDim2',
	[Vector2] = 'Vector2', [Vector2int16] = 'Vector2int16', [Vector3] = 'Vector3', [Vector3int16] = 'Vector3int16'
};
