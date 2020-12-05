% change your function name to your group number
function G07(selpath)

    %load your trained neural network model
    pretrained = load('detector.mat');
    detector = pretrained.detector; 
    
    %get all jpg images in selpath
    imageList = dir( strcat(selpath,"/*.jpg") );
    
    % change your group name
    groupName = "G07";
    
    % output file name
    outfile = strcat(groupName,"_",selpath,".txt");
    
    fid=fopen(outfile,'w');
    for i = 1:length(imageList)
        filename = fullfile(imageList(i).folder, imageList(i).name );
        I = imread( filename );
        tI = zeros(227,227,3,'uint8');
        ratio = 227 / max(size(I));
        tI(1:round(size(I, 1) * ratio), 1 : round(size(I, 2) * ratio), :) = imresize( I, round([size(I, 1) size(I, 2)] * ratio));
        % if you only do classfication on Single Database , use classfy
        % function
        [bboxes, scores, labels] = detect(detector, tI);
        [selectedBboxes,selectedScores,selectedLabels,index] = selectStrongestBboxMulticlass(bboxes,scores,labels, 'OverlapThreshold' , 0.1 );
        
        % print your pridict labels to file.
        fprintf( fid,"%s ",  imageList(i).name );
        for j = 1:length(selectedLabels)
            fprintf( fid,"%s ",selectedLabels(j) );
        end
        fprintf( fid,"\n" );
    end 
    fclose(fid);
    
end
