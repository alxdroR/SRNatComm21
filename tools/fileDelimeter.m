function fileDelim = fileDelimeter
% returns the proper file delimeter to use when constructing path names 

if ismac
    fileDelim = '/';
elseif ispc
    fileDelim = '\';
else
    error('please display the file deliminator for your system');
end
end

