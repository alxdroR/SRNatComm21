function y = barrierALEX(a,b,bvalue)

% returns a vector equal in length to `a` with all values of 
% a <= b set to bvalue.  Values a>b remain unchanged 
y = a.*(a>b);
y(a<=b) = bvalue;
end

