function [Q,R] = gramSchmidt(A)

[m,n] = size(A);
Q = zeros(m,n);
R = zeros(n,n);
for j = 1 : n 
    v = A(:,j); % v begins as column j of A;
    for i = 1 : j -1 
        R(i,j) = Q(:,i)'*A(:,j); % modify A(:,j) to v for more accuracy 
        v = v - R(i,j)*Q(:,i); % subtract the projection (q'a)q = (q'v)q 
    end % v is now perpendicular to all q1, ... , qj-1
    R(j,j) = norm(v);
    Q(:,j) = v/R(j,j); % normalize v to be the next unit vector qj
end
end

