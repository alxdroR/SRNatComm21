function meta = makeMetaDataStruct(varargin)
options = struct('default',false);
options = parseNameValueoptions(options,varargin{:});

if options.default
    meta = struct('objective','40X','power','not specified','age','7dpf','zspacing','5mu','excWavelength','930nm','notes',[]);
else
    meta = struct('objective','not specified','power','not specified','age','not specified','zspacing','not specified','excWavelength','not specified','notes',[]);
end
end

