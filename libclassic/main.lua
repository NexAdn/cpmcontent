-- http://www.computercraft.info/forums2/index.php?/topic/26305-classic-pretty-oop-in-cc/

-- Classic by Kouksi44 : Class framework for Lua / CC


local Class={}
local classes={}
local interfaces={}
local _class;
local Object={};
local ObjectProxy={}
local Property={}
local SecurityContext={}
local Utils={}

Utils.luaTypes={
  ["method"]=true;
  ["String"]=true;
  ["Table"]=true;
  ["number"]=true;
  ["thread"]=true;
  ["boolean"]=true;
}

function Utils.isTypeValue(obj)
  for k,v in pairs(obj.modifiers) do
    if v == "Table" or v== "String" then
      return "LuaType", string.lower(v)
    end
    if v == "method" then
      return "LuaType","function"
    end
    if Utils.luaTypes[v] then
      return "LuaType" , v
    elseif classes[v] then
      return "ClassType" , v
    end
  end
  return false
end

function Utils.isClassType(value)
  if value.isInnerProxy or value.isOuterProxy then
    if value.getClass then
      return true
    end
  end
  return false
end

function Utils.getClassType(value)
   if value.isInnerProxy or value.isOuterProxy then
    if value.getClass then
      return value:getClass().name
    end
  end
  return "Unknown ClassType"
end

function Utils.getValueType(value)
  if Utils.isClassType(value) then
    return Utils.getClassType(value)
  end
  if type(value) == "table" or type(value) == "string" then
    return type(value)
  end
  if Utils.luaTypes[type(value)] then
    return type(value)
  end
  error("[ValueTypeError] Unknown TypeValue (no ClassValue or LuaType)")
end

function Utils.hasType(value,_type)
  if type(value)=="nil" then
    return true
  end
  if classes[_type] and Utils.isClassType(value) then
    return (Utils.getClassType(value) == _type) or value:getClass():subclassOf(_type)
  end
  return type(value) == _type
end

function Utils.removeModifier(mod,_type)
  for k,v in pairs(mod.modifiers) do
    if v == _type then
      table.remove(mod.modifiers,k)
    end
  end
end

function createAbstractMethod(className,methodName)
  local abstractObj = {
    classname = className;
    methodname = methodName;
    __type = "AbstractMethod";
  }
  return abstractObj
end
      


local mods={
  ["public"] = true;
  ["private"] = true;
  ["final"] = true;
  ["shared"] = true;
  ["property"] = true;
  ["abstract"] = true;
  --["protected"]=true;
}

local chainModifiers=function(left,right)
  if(type(left)=="table" and left._type=="modifier") and (type(right)=="table" and right._type=="modifier") then
    for _,v in pairs(left.additional) do
      table.insert(right.additional,v)
    end
    return right
  elseif (type(left)=="table" and left.type=="class") or (type(right)=="table" and right.type=="class") then
    local name = ((type(left)=="table" and left.type=="class") and left.name) or right.name
    local rMod={}
    if (type(left)=="table" and left.type=="class") then
      if not (type(right)=="table" and right._type=="modifier") then
        local mVal={
          modifiers={};
          value=right;
          _type="modified";
        }
        for _,v in pairs(rawget(left,"additional")) do
          table.insert(mVal.modifiers,v)
        end
        return mVal
      end
      for _,v in pairs(rawget(left,"additional")) do
        table.insert(right.additional,v)
      end
      return right
    else
      for _,v in pairs(left.additional) do
        table.insert(rawget(right,"additional"),v)
      end
      return right
    end
  elseif (type(left)=="table" and left._type=="modifier") and not (type(right)=="table" and (right._type=="modifier" or right.type=="class")) then
    local mVal={ -- value object with one or several modifiers ( e.g. public or static)
      modifiers={};
      value=right;
      _type="modified"
    }
    for _,v in pairs(left.additional) do
      table.insert(mVal.modifiers,v)
    end
    return mVal
  end
end


  
    
local Modifier=function(_type)
  if not mods[_type] and not (type(_type) == "table" and _type._type == "ValuedType") then
    error("Unknown modifier",2)
  end
  local mod={
    _type="modifier";
    additional={[1]=(type(_type) == "table" and _type.valueType) or _type} ;
  }
  return setmetatable(mod,{__sub=chainModifiers})
end

local ValueType = function(name)
  local obj = {}
  obj.valueType=name
  obj._type="ValuedType"
  return obj
end

_G.public = Modifier("public")
_G.private = Modifier("private")
_G.final = Modifier("final")
_G.shared = Modifier("shared")
_G.property = Modifier("property")
_G.abstract = Modifier("abstract")


for k,v in pairs(Utils.luaTypes) do
  _G[k]=Modifier(ValueType(k))
end


  


local function len(tbl)
 local c=0;
 for _ in pairs(tbl) do
	 c=c+1
 end
 return c
end

local function unique(tbl)
 local t={}
 for k,v in pairs(tbl) do
	 if type(v)=="table" then
     if typeof(v) == "instance" then
       t[k] = v.invokeMethod("clone")
		 elseif len(v)==0 then
			 t[k]={}
		 else
			 t[k]=unique(v)
		 end
	 else
		 t[k]=v
	 end
 end
 return t
end


local function createObjectProxy(t,class,inner)
	local object=Object(class)
  local super=nil
  local proxy={isOuterProxy=true}
  local innerProxy={isOuterProxy=false}
	if class.inherits then
    if class.super:hasInit() then
		super=class.super:instance(true,true)
    else
      super=class.super:instance(false,true)
    end
    
    setmetatable(innerProxy,{__index=function(t,k) if k=="super" then return super end local level = object:getContext():getAccessLevel() if object:getValue(k,level,false)==nil then super.securityContext:setAccessLevel(level+1)   return super[k] end if type(object:getValue(k,level,false)) == "function" then return function(s,...) local args = {...} if (typeof(s) == "instance" and s.hashValue()==object.raw.hashValue()) then return object:getValue(k,level)(innerProxy,unpack(args)) else if (typeof(s) == "instance" and s.getClass():subclassOf(object.raw.getClass().name)) then return object:getValue(k,level)(innerProxy,unpack(args)) else table.insert(args,1,s) return object:getValue(k,level)(innerProxy,unpack(args)) end end end else return object:getValue(k,level) end end;
 												     __newindex=function(t,k,v) local level = object:getContext():getAccessLevel() super.securityContext:setAccessLevel(level+1) if super[k] and not object:getValue(k,level) then super.securityContext:setAccessLevel(level+1) super[k] = v else object:setValue(k,v,level) end  end; } )
    
    
		setmetatable(proxy,{__index=function(t,k)   if k=="super" then return super end  local level = object:getContext():getAccessLevel()+1 if object:getValue(k,level,false)==nil then  super.securityContext:setAccessLevel(level+1) return super[k] end if type(object:getValue(k,level,false))=="function" then  return function(s,...) local args = {...} if (typeof(s) == "instance" and s.hashValue()==object.raw.hashValue()) then return object:getValue(k,level)(innerProxy,unpack(args)) else if (typeof(s) == "instance" and s.getClass():subclassOf(object.raw.getClass().name)) then return object:getValue(k,level)(innerProxy,unpack(args)) else table.insert(args,1,s) return object:getValue(k,level)(innerProxy,unpack(args)) end end end else return object:getValue(k,level) end end;
 												__newindex=function(t,k,v) local level = object:getContext():getAccessLevel()+1 super.securityContext:setAccessLevel(level+1) if super[k] and not object:getValue(k,level) then super.securityContext:setAccessLevel(level+1) super[k] = v else object:setValue(k,v,level) end end; } )
	else
    setmetatable(innerProxy,{__index=function(t,k)   local level=object:getContext():getAccessLevel() if type(object:getValue(k,level,false)) == "function" then return function(s,...) local args = {...} if (typeof(s) == "instance" and s.hashValue()==object.raw.hashValue()) then return object:getValue(k,level)(innerProxy,unpack(args)) else if (typeof(s) == "instance" and s.getClass():subclassOf(object.raw.getClass().name)) then return object:getValue(k,level)(innerProxy,unpack(args)) else table.insert(args,1,s) return object:getValue(k,level)(innerProxy,unpack(args)) end end end else return object:getValue(k,level) end end;
 												     __newindex=function(t,k,v)  object:setValue(k,v,0)  end; } )
    
    
		setmetatable(proxy,{__index=function(t,k)   local level=object:getContext():getAccessLevel()+1 if type(object:getValue(k,level,false))=="function" then  return function(s,...) local args = {...} if (typeof(s) == "instance" and s.hashValue()==object.raw.hashValue()) then return object:getValue(k,level)(innerProxy,unpack(args)) else if (typeof(s) == "instance" and s.getClass():subclassOf(object.raw.getClass().name)) then return object:getValue(k,level)(innerProxy,unpack(args)) else table.insert(args,1,s) return object:getValue(k,level)(innerProxy,unpack(args)) end end end else return object:getValue(k,level) end end;
 												__newindex=function(t,k,v)  object:setValue(k,v,1) end; } )
	end
  object:setInner(innerProxy)
  
	return ((inner and innerProxy) or proxy), innerProxy
end

function typeof(object)
	if type(object)=="table" then
		if type(object.getClass) == "function" then
      return "instance"
    end
  end
  return type(object)
end

function using(path,env)
  local path = path:gsub("%.","/")
	if not fs.exists(path) then
    if not fs.exists(path..".lua") then
      error("Can`t import class from: "..path..". Unknown classpath.",2)
    else
      path=path..".lua"
      local f = io.open(path,"r")
      local c = f:read()
      local func = setfenv(loadstring(c),env)
      f:close()
      local okay,err = pcall(func)
      if not okay then
        error("Failed to load class from: "..path.." . An error occured while loading the class.",2)
      end
    end
  else
    local f = io.open(path,"r")
    local c = f:read()
    local func = setfenv(loadstring(c),env)
    f:close()
    local okay,err = pcall(func)
    if not okay then
      error("Failed to load class from: "..path..". An error occured while loading the class.",2)
    end
  end
end


function Class:getField(field)
	return type(self.raw[field])~="function" and self.raw[field]
end

function Class:getSuper()
	return self.super:newProxy()
end

function Class:subclassOf(super)
	if self.inherits then
		if self.super.name==super then
			return true
		else
			return self.super:subclassOf(super)
		end
	end
	return false
end

function Class:superOf(sub)
	return classes[sub]:subclassOf(self.name)
end

function Class:hashValue()
  return tostring(self.raw):sub(8)
end

function Class.new(name)
	local obj={}
	obj.type="class"
	obj.name=name
	obj.constructed=false
	obj.inherits=false
	obj.super=nil
	obj.raw={}
	obj.properties={}
  obj.interfaces={}
  obj.modifiedMembers={}
  obj.valueTypes={}
  obj.additional={[1]=name}
  obj.abstractMethods = {}
	setmetatable(obj,{__index=Class,__newindex=obj.raw,__call=function(self,...) return obj:instance((obj.raw.init~=nil),false,...) end,__sub=chainModifiers})
	if not classes[name] then
		classes[name]=obj
		_G[obj.name]=obj
		_class=classes[name]
	end
	return function(body)
		obj:construct(body)
	end
end

function Class:extend(name)
	if not classes[name] then
		error("Super class not found",3)
	end
	rawset(self,"inherits",true)
	rawset(self,"super",classes[name])
	return function(body)
		self:construct(body)
	end
end

function Class:instance(hasInit,isInherit,...)
  if hasInit then
  	if not self.raw.init then
  		error("Cant´t load class without init",3)
  	end
    local args = { n = select("#",...),...}
    local proxy,innerProxy=ObjectProxy(self,isInherit)
    proxy:init(unpack(args,1,args.n))
  	return proxy
  else
  	return ObjectProxy(self,isInherit)
  end
end

function Class:checkMembers()
  for k,v in pairs(self.raw) do
    if type(v)=="table" and v._type=="modified" then
      local isAbstract = false
      for k,v in pairs(v.modifiers) do
        if v == "abstract" then
          isAbstract = true
        end
      end
      if isAbstract then
        self.raw[k] = createAbstractMethod(self.name,k)
        self.abstractMethods[k] = true
      else
        self.modifiedMembers[k] = v
      end
    end
  end
end


function Class:getModifiedMembers()
  return self.modifiedMembers
end


function Class:getShared(index)
  return self.raw[index].value
end

function Class:setShared(index,value)
  self.raw[index].value=value
end

function Class:checkTypeValues()
  for k,v in pairs(self.raw) do
    if type(v) == "table" and v._type == "modified" then
      local isTypeVal, _type = Utils.isTypeValue(v)
      if isTypeVal then
        self.valueTypes[k] = {valueType=_type}
        if not Utils.hasType(v.value,_type) then
          error("[ValueTypeError] Attempt to set member: "..k.." with wrong type: ".. _type,4)
        end
      end
    end
  end
end


function Class:construct(body)
	for k,v in pairs(body) do
		  self.raw[k]=v
  end
  self:checkTypeValues()
  self:checkMembers()
end

function Class:newProxy()
	return setmetatable({},{__index=self,__newindex=function() error("Attempt to modify class",3) end})
end

function Class:implement(interface)
	if not interfaces[interface] then
		error("Interface does not exist",3)
	end
		self.raw=unique(interfaces[interface])
    getmetatable(self).__newindex=self.raw
    self.interfaces[interface]=interfaces[interface]
	return function(body)
		self:construct(body)
	end
end

function Class:hasInit()
  return type(self.raw.init)=="function"
end


local function extends(name)
	return _class:extend(name)
end

local function implements(name)
	return _class:implement(name)
end

local function interface(name)
	if interfaces[name] then
		error("Interface already exists")
	end
	interfaces[name]={}
	return function(body)
		interfaces[name]=body
	end
end

function Object.new(class)
	local obj={}
  obj.proxy = {}
	obj.type="object"
	obj.raw=unique(class.raw)
  obj.modified=class:getModifiedMembers()
	obj.raw.getClass=function(...) return class:newProxy() end
  obj.raw.hashValue = function(...) return tostring(obj.raw):sub(8) end
  obj.raw.invokeMethod = setmetatable({},{__call = function(_,method,...) if not type(Object[method]) == "function" then error("Invalid method invokation.") end return Object[method](obj,...) end})
  obj.__accessTypeGet="GET_VALUE"
  obj.__accessTypeSet="SET_VALUE"
  obj.securityContext=SecurityContext()
  obj.raw.securityContext=obj.securityContext
  obj.typedValues = class.valueTypes
  obj.propertyFlags = {}
  setmetatable(obj,{__index=Object})
  Object.prepareMembers(obj)
	return obj
end


function Object:prepareMembers()
  for k,v in pairs(self.modified) do
    rawset(self.raw,k,v.value)
  end
end

-- function Object:checkForAbstractDefinitions()
--   for k,v in pairs(self.abstracts) do
--     if type(self.raw[k]) ~= "function" then
--       if self.raw[k].classname ~= self.raw.getClass().name then
--         error("Abstract method:"..k.." must be overriden in any extended classes.",2)
--       end
--     else
--       self.abstracts[k] = false
--     end
--   end
--
--   if self.raw.getClass().inherits then
--     for k,v in pairs
-- end

  

function Object:clone()
  local nObj = self.raw.getClass():instance((self.raw.init~=nil),false)
  for k,v in pairs(self.raw) do
    if not k == "getClass" or k == "hashValue" or k == "invokeMethod" then
      if self:isModifiedMember(k,"shared") then end
      if not self:isModifiedMember(l,"final") then
        nObj.invokeMethod("setValue",k,v,0)
      end
    end
  end
  return nObj
end

function Object:getContext()
  return self.securityContext
end

function Object:getValueType(index)
  return self.typedValues[index].valueType
end

function Object:isTypedValue(index)
  if self.typedValues[index] then
    return true
  end
  return false
end


function Object:getValue(index,accessLevel,cProp)
  --print("Getting value with level: ".. (accessLevel or " "))
  local canAccess
  if accessLevel~=0 then
    canAccess = self:checkMemberAccess(index,self.__accessTypeGet)
  else
    canAccess=true
  end
  if canAccess then
    if self:isModifiedMember(index,"shared") then
      return self.raw.getClass():getShared(index)
    else
      if self:isModifiedMember(index,"property") then
				if cProp == false then
					return self.raw[index] or nil
				end
        if self.propertyFlags[index] ~= true  then
          return self:callGetter(index)
        else
          return self.raw[index] or nil
        end
      else
        return self.raw[index] or nil
      end
    end
  end
  return nil
end


function Object:isProperty(index)
	if type(self.raw[index])=="table" then
    if self.raw[index]._type=="property" and self.raw[index].get and self.raw[index].set then
      return true
    end
  end
  return false
end

function Object:checkMemberAccess(index,accessType)
  if accessType==self.__accessTypeGet then
    if self:isModifiedMember(index,"private") then
      return false
    else
      return true
    end
  elseif accessType==self.__accessTypeSet then
    if self:isModifiedMember(index,"private") then
      error("Attempt to modify private member.",4)
    elseif self:isModifiedMember(index,"final") then
      error("Attempt to modify final member.",4)
    else
      return true
    end
  end
end
  

function Object:setValue(index,value,accessLevel)
  if accessLevel~=0 then
    canAccess = self:checkMemberAccess(index,self.__accessTypeSet)
  else
    canAccess=(self:isModifiedMember(index,"final") and false) or (not self:isModifiedMember(index,"final") and true)
    if not canAccess then
      error("Attempt to modify final member.",3)
    end
  end
  
  if canAccess then
    if self:isTypedValue(index) then
      if not Utils.hasType(value,self:getValueType(index)) then
        error("[ValueTypeError] Attempt to set member:"..index.." with wrong type")
      end
    end
    if self:isModifiedMember(index,"shared") then
      self.raw.getClass():setShared(index,value)
    else
      if self:isModifiedMember(index,"property") then
        if not self.propertyFlags[index] then
          self:callSetter(index,value)
        else
          self.raw[index] = value
        end
      else
        self.raw[index]=value
      end
    end
  end
end

function Object:isModifiedMember(index,_type)
  if self.modified[index] then
    if _type then
      for k,v in pairs(self.modified[index].modifiers) do
        if v==_type then
          return true
        end
      end
    else
      return true
    end
  end
  return false
end

function Object:callGetter(index)
  self.propertyFlags[index] = true
  local getter = "get"..index:sub(1,1):upper()..index:sub(2,#index)
  if type(self.raw[getter]) == "function" then
    return self:proxyGetter(getter)
  else
    return self.raw[index]
  end
end

function Object:callSetter(index,value)
  self.propertyFlags[index] = true
  local setter = "set"..index:sub(1,1):upper()..index:sub(2,#index)
  if type(self.raw[setter]) == "function" then
    self:proxySetter(setter,value)
  else
    self.raw[index] = value
  end
end

function Object:setInner(proxy)
  self.proxy = proxy
end

function Object:proxySetter(setter,...)
  if not type(setter)=="function" then
    error("Can't invoke index: "..setter.." through proxy (not a function)")
  end
  self.raw[setter](self.proxy,...)
  self.propertyFlags = {}
end

function Object:proxyGetter(getter)
  if not type(getter)=="function" then
    error("Can't invoke index: "..getter.." through proxy (not a function)")
  end
  local fResult = self.raw[getter](self.proxy)
  self.propertyFlags = {}
  return fResult
end

    
function SecurityContext.new()
  local obj={}
  obj.accessLevel=0
  return setmetatable(obj,{__index=SecurityContext})
end

function SecurityContext:setAccessLevel(level)
  self.accessLevel=level
end

function SecurityContext:getAccessLevel()
  local level=self.accessLevel
  self.accessLevel=0
  return level
end

  



setmetatable(Class,{__call=function(self,name) return Class.new(name) end})
setmetatable(Object,{__call=function(self,class) return Object.new(class) end})
setmetatable(ObjectProxy,{__call=createObjectProxy})
setmetatable(Property,{__call=function(self,value) return Property.new(value) end})
setmetatable(SecurityContext,{__call=function(self) return SecurityContext.new() end})

_G.class=Class
_G.extends=extends
_G.implements=implements
_G.interface=interface