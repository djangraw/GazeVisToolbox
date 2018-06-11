function [k_min_ind, k_min] = GetElbow(ks)

% Find 'elbow' of an asymptotic plot. Often used for selecting the number
% of components.
%
% k_min_ind = GetElbow(ks)
%
% INPUTS:
% -ks is a 1xn vector of values approaching an asymptote.
%
% OUTPUTS:
% -k_min_ind is the index of the element at the elbow.
% -k_min is the value at the elbow (=ks(k_min_ind)).
%
% Python function from tedana.py adapted for MATLAB.
% Created 9/25/15 by DJ.
% Updated 2/9/17 by DJ - renamed GetElbow.

% Comments below are the python equivalents.

% nc = ks.shape[0]
nc = size(ks,2);
% coords = np.array([np.arange(nc),ks])
coords = [(1:nc); ks];
% p  = coords - np.tile(np.reshape(coords[:,0],(2,1)),(1,nc))
p = coords - repmat(coords(:,1),1,nc);
% b  = p[:,-1] 
b = p(:,end);
% b_hat = np.reshape(b/np.sqrt((b**2).sum()),(2,1))
b_hat = b./sqrt(sum(b.^2))';
% proj_p_b = p - np.dot(b_hat.T,p)*np.tile(b_hat,(1,nc))
proj_p_b = p - repmat(b_hat'*p,2,1).*repmat(b_hat,1,nc);
% d = np.sqrt((proj_p_b**2).sum(axis=0))
d = sqrt(sum(proj_p_b.^2,1));
% k_min_ind = d.argmax()
[~,k_min_ind] = max(d);
% k_min  = ks[k_min_ind]
k_min = ks(k_min_ind);
% return k_min_ind