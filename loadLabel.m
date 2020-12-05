function [region, label] = loadLabel(dir, isSingle)
fileID = fopen(dir, 'r');
data = textscan(fileID,'%d,%d,%d,%d,%d,%d,%d,%d,%s');
coordinate = cell(1,4);
for i = 1 : 4
    tmp = (i - 1) * 2 + 1;
    coordinate(1,i) = {[double(data{tmp}) double(data{tmp + 1})]};
end
if isSingle
    region = zeros(1,4);
    region(1) = coordinate{1}(1);
    region(3) = coordinate{1}(1);
    region(2) = coordinate{1}(2);
    region(4) = coordinate{1}(2);
    for i = 2 : 4
        region(1) = min(region(1), coordinate{i}(1));
        region(3) = max(region(3), coordinate{i}(1));
        region(2) = min(region(2), coordinate{i}(2));
        region(4) = max(region(4), coordinate{i}(2));
    end
    region(3) = region(3) - region(1);
    region(4) = region(4) - region(2);
    
else
    region = cell(size(coordinate{1}, 1), 1);
    for j = 1 : size(coordinate{1}, 1)
        region{j} = zeros(1, 4);
        region{j}(1) = coordinate{1}(j, 1);
        region{j}(3) = coordinate{1}(j, 1);
        region{j}(2) = coordinate{1}(j, 2);
        region{j}(4) = coordinate{1}(j, 2);
        for i = 2 : 4
            region{j}(1) = min(region{j}(1), coordinate{i}(j, 1));
            region{j}(3) = max(region{j}(3), coordinate{i}(j, 1));
            region{j}(2) = min(region{j}(2), coordinate{i}(j, 2));
            region{j}(4) = max(region{j}(4), coordinate{i}(j, 2));
        end
        region{j}(3) = region{j}(3) - region{j}(1);
        region{j}(4) = region{j}(4) - region{j}(2);
    end
end
label = data{9};
fclose(fileID);
end

