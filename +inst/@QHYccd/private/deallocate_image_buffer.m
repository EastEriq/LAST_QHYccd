function deallocate_image_buffer(QC)
    % check if the buffer is defined, so that the function can
    %  be called harmlessly multiple times
    if isa(QC.pImg,'lib.pointer')
        delete(QC.pImg) % delete(libpointer just zeroes it, I think, does not eliminate it)
    end
    if isa(QC.pImg,'POSIXipc.shm')
        for i=1:numel(QC.pImg)
            delete(QC.pImg(i)); % iterate, till I decide to vectorize shm methods
        end
    end
end
