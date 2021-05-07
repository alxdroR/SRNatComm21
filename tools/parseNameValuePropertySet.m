classdef parseNameValuePropertySet
    %parseNameValuePropertySet  - allow subclass to quickly implement the construction of changing defaults if user enters
    properties (SetAccess=protected, Hidden=true)
        fieldsOfInterest
    end
    methods
        function obj = parseNameValuePropertySet(varargin)
            if ~isempty(varargin)
                obj.fieldsOfInterest = varargin{1};
            end
        end
        function obj = setDefaults(obj,options)
            if ~isempty(obj.fieldsOfInterest)
                fn = obj.fieldsOfInterest;
            else
                % set all properties within options structure
                fn = fieldnames(options);
            end
            pout=properties(obj);
            fn2set = intersect(fn,pout);
            for k = 1 : length(fn2set)
                prop2set = fn2set{k};
                optionsValue = options.(prop2set);
                if ~isempty(optionsValue)
                    obj.(prop2set) = optionsValue;
                end
            end
        end
    end
    methods (Static)
        function merged_struct = mergeStructs(struct_a,struct_b)
            %%if one of the structres is empty do not merge
            if isempty(struct_a)
                merged_struct=struct_b;
                return
            end
            if isempty(struct_b)
                merged_struct=struct_a;
                return
            end
            %%insert struct a
            merged_struct=struct_a;
            %%insert struct b
            f = fieldnames(struct_b);
            size_a=length(struct_a);
            size_b=length(struct_b);
            if size_a == 1 && size_b == 1
                for i = 1:length(f)
                    merged_struct.(f{i}) = struct_b.(f{i});
                end
            else
                for j=1:length(struct_b)
                    for i = 1:length(f)
                        merged_struct(size_a+j).(f{i}) = struct_b.(f{i});
                    end
                end
            end
        end
    end
end

