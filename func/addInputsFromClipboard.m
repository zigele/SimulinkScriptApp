function addedBlockNames = addInputsFromClipboard(btype)
    % 获取剪贴板内容
    clipboardText = clipboard('paste');
    
    % 处理不同版本MATLAB的兼容性
    if verLessThan('matlab', '9.1') % R2016b之前版本
        blockNames = regexp(clipboardText, '\r?\n|\r', 'split');
    else
        blockNames = split(clipboardText, newline);
        blockNames = blockNames';
    end
    
    % 获取当前打开的Simulink模型
    modelName = gcs;
    if isempty(modelName)
        error('没有打开的Simulink模型');
    end
    
    % 获取当前模型中的Inport模块数量
    existingBlocks = find_system(modelName, 'BlockType', 'Inport');
    startY = 100 + numel(existingBlocks) * 50;
    
    % 准备存储新添加模块的完整名称
    addedBlockNames = {};
    
    % 添加每个模块
    for i = 1:numel(blockNames)
        if isempty(strtrim(blockNames{i}))
            continue;
        end
        
        cleanName = matlab.lang.makeValidName(blockNames{i});
        fullBlockPath = [modelName '/' cleanName];
        
        if strcmp(btype, 'In1') 
            % 添加输入端口模块（自动添加唯一后缀）
            blkHandle = add_block('simulink/Commonly Used Blocks/In1', ...
                                 fullBlockPath, ...
                                 'MakeNameUnique', 'on');
        elseif strcmp(btype, 'Out1')
            % 添加输入端口模块（自动添加唯一后缀）
            blkHandle = add_block('simulink/Commonly Used Blocks/Out1', ...
                                 fullBlockPath, ...
                                 'MakeNameUnique', 'on');
        else

        end
        
        % 获取系统生成的唯一完整路径
        uniquePath = getfullname(blkHandle);
        addedBlockNames{end+1} = uniquePath;
    end
end