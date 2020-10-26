function img=unpackImgBuffer(pImg,w,h,channels,bp)
    % Conversion of an image buffer to a matlab image
    % trying to make this work for color/bw, 8/16bit, binning

    % IIUC https://www.qhyccd.com/bbs/index.php?topic=6038.msg31725#msg31725
    %  color images should always be 3x8bit
    if channels==3
        img=reshape([pImg.Value(3:3:3*w*h);...
                     pImg.Value(2:3:3*w*h);...
                     pImg.Value(1:3:3*w*h)],w,h,3);
    else
        % for 2D we could perhaps just reshape the pointer
        if bp==8
            img=reshape(pImg.Value(1:w*h),w,h);
        else
            % this one takes ~170ms
            %  img=reshape(uint16(pImg.Value(1:2:2*w*h))+...
            %  bitshift(uint16(pImg.Value(2:2:2*w*h)),8),w,h);
            % and this one ~100ms
            img=reshape(typecast(pImg.Value(1:2*w*h),'uint16'),w,h);
        end
    end
end
