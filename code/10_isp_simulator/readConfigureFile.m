function im = readConfigureFile( ConfigFilePath )



if nargin<1 || isempty(ConfigFilePath)
    [FileName,PathName] = uigetfile('*.txt;*.mat','Select the sensor configure file');
    ConfigFilePath = [PathName, FileName];
end

[pathstr,imgName,ext] = fileparts(ConfigFilePath);

% im.rawWidth = 0;
% im.rawHeight = 0;
im.bkd = 0;
im.bayer = '';

if strcmpi(ext,'.mat')
    load(ConfigFilePath);
    if ~exist('op','var')
        errordlg('Not the right Option File!');
    else
        switch lower(op.readmode)
            case '16'
                im.bit = 10;
                im.type = 'raw';
            case '16s'
                im.bit = 10;
                im.type = 'bin';
            case '8s'
                im.bit = 8;
                im.type = 'bin';
            case 'bmp'
                im.bit = 8;
                im.type = 'bmp';
            case '8'
                im.bit = 8;
                im.type = 'raw';
            case 'mipi'
                im.bit = 10;
                im.type = 'mipi';
            case '12s'
                im.bit = 12;
                im.type = 'bin';
            case '10'
                im.bit = 10;
                im.type = 'qc';
        end
        im.bayer = op.bayerPattern;        
        if isfield(op,'width'), im.rawWidth = op.width;end        
        if isfield(op,'height'),im.rawHeight = op.height;end        
        if isfield(op,'blackLevel'),im.bkd = op.blackLevel;else im.bkd = 0;end        
        if isfield(op,'fnumber'), im.Fnum = op.fnumber;end        
    end    
else
    fid = fopen(ConfigFilePath);
    str1 = textscan(fid,'%s','Delimiter','\n');
    str1 = char(str1{1});
    str = lower(str1);
    [row,col]=size(str);
    
    edge = [0 0 0 0];
    
    for i = 1:row
        if ~isempty(strfind(str(i,:),'sensor name'))
            im.sensor = strtrim(str1(i,13:col));
        elseif ~isempty(strfind(str(i,:),'image width'))
            im.rawWidth = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'image height'))
            im.rawHeight = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'black level'))
            im.blc = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'image type'))
            im.type = lower(strtrim(str(i,12:col)));
        elseif ~isempty(strfind(str(i,:),'bayer pattern'))
            im.bayer = lower(strtrim(str(i,15:col)));
        elseif ~isempty(strfind(str(i,:),'cell type'))
            im.cell = lower(strtrim(str(i,11:col)));
        elseif ~isempty(strfind(str(i,:),'image bit'))
            im.bit = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'f number'))
            im.Fnum = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'lens transmission'))
            im.tr = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'pixel size'))
            im.pixel = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'top'))
            edge(1) = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'bottom'))
            edge(2) = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'left'))
            edge(3) = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'right'))
            edge(4) = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'input format'))
            im.inputdata = strtrim(str1(i,14:col));
         elseif ~isempty(strfind(str(i,:),'output format'))
            im.outputdata = strtrim(str1(i,15:col));
        elseif ~isempty(strfind(str(i,:),'bit shift'))
            im.bitshift = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        elseif ~isempty(strfind(str(i,:),'data format'))
            im.data = strtrim(str1(i,13:col));
        elseif ~isempty(strfind(str(i,:),'pixel offset'))
            im.bit = str2double(regexp(str(i,:),'-?\d+\.?\d*|-?\d*\.?\d+','match'));
        end
    end
    
    if sum(edge) > 0
        im.edge = int16(edge);
    end
    
end

if ~strcmpi(im.type,'bmp')
    if ~strcmpi(im.type,'bin')||~strcmpi(im.type,'quadBin')
        if ~isfield(im,'rawWidth')
            g = msgbox('Width error');
            uiwait(g);
        elseif ~(im.rawWidth >= 0)
            g = msgbox('Width error');
            uiwait(g);
        end
        
        if ~isfield(im,'rawHeight')
            g = msgbox('Height error');
            uiwait(g);
        elseif ~(im.rawHeight >= 0)
            g = msgbox('Height error');
            uiwait(g);
        end
    end
    
    if ~isfield(im,'bit')
        g = msgbox('Image bit error');
        uiwait(g);
    elseif ~(im.bit >= 0)
        g = msgbox('Image bit error');
        uiwait(g);
    elseif im.bit > 16
        g = msgbox('Only support  <=16 bit images');
        uiwait(g);
    end
    
    if strcmpi(im.bayer,'mono')
        im.cell = 'Mono';
        im.bayer = '';
    elseif isempty(im.bayer) && ~strcmpi(im.cell,'mono')
        g = msgbox('Bayer Pattern error');
        uiwait(g);
    end
end

if ~(im.bkd >= 0)
    g = msgbox('Background level error');
    uiwait(g);
end



   
end



