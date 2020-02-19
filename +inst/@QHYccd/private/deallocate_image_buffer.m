function deallocate_image_buffer(QC)
    % check if the buffer is defined, so that the function can
    %  be called harmlessly multiple times
    if isa(QC.pImg,'lib.pointer')
        delete(QC.pImg)
    end
end
