function [pNameSTL, mask, outLims] = loadSegmentations(info)

[~, pNameSTL] = uigetfile('*.stl', 'Select one 3d .stl from Mimics');
nframes = info.nframes;

% check that the number of .stl files matches number of frames
stlFiles = dir([pNameSTL, '\*stl']);
mask = zeros([info.imSize info.nframes]);
if length(stlFiles) ~= nframes
    warning('number of stl files does not match number of image frames, please check')
else % load them in
    fprintf('loading %i stl files\n', nframes)
    h = waitbar(0,'loading segmentations');
    for ii = 1:nframes
        [f,v] = stlread_speech(fullfile(stlFiles(ii).folder,stlFiles(ii).name));
        % convert our coordinate system and add to mask
        sl = round((v(:,1)-info.offcentre(3))/info.pixdim(3) + ceil(info.imSize(3)/2));
        sl(sl==0)=1;
        
        row = round((v(:,2)-info.offcentre(1))/info.pixdim(1) + ceil(info.imSize(1)/2));
        row(row==0)=1;
        
        col = round((v(:,3)-info.offcentre(2))/info.pixdim(2) + ceil(info.imSize(2)/2));
        col(col==0)=1;
        
        IN = inpolyhedron(f,cat(2,row,col,sl),1:info.imSize(1),1:info.imSize(2),1:info.imSize(3));
        
        N = 2;
        kernel = ones(N, N, N) / N^3;
        blurryImage = convn(double(IN), kernel, 'same');
        newBinaryImage = blurryImage > 0.5;
        mask(:,:,:,ii) = newBinaryImage;
        
        if mod(ii,2) == 1
            waitbar(ii/nframes,h)
        end
        
    end
end
close(h)

% do some flipping
mask = permute(mask,[2 1 3 4]);
mask = flip(flip(mask,3),2);

% establish limits for 3D viewing
[x,y,z] = ind2sub(size(mask,1:3),find(mean(mask,4)));
outLims = [min(y) min(x) min(z); max(y) max(x) max(z)];
disp('Load segmentations finished');
return