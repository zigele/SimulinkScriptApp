function [successCount, signalNames] = setNameToSelectedBlocks()
    % 获取当前系统中所有被选中的模块
    selectedBlocks = find_system(gcs, 'LookUnderMasks', 'none', 'FollowLinks','off','type','block', 'Selected', 'on');
    
    if isempty(selectedBlocks)
        error('NameTool:NoSelection', '请先选中需要处理的模块');
    end
    
    % 初始化计数器
    successCount = 0;
    signalNames = {}; % 存储设置的信号线名称
    
    % 遍历所有选中的模块
    for i = 1:length(selectedBlocks)
        block = selectedBlocks{i};
        try
            % 获取模块类型并跳过子系统
            blockType = get_param(block, 'BlockType');
            if strcmp(blockType, 'SubSystem') % 关键修改：剔除SubSystem
                continue; 
            end
            
            % 获取模块名称并清理换行符
            blockName = strrep(get_param(block, 'Name'), newline, ' ');
            
            % 确定要处理的端口类型
            ports = get_param(block, 'PortHandles');
            
            if strcmp(blockType, 'Outport')
                targetPorts = ports.Inport;  % 输出模块处理输入端口
            else
                targetPorts = ports.Outport; % 普通模块处理输出端口
            end
            
            % 跳过无可用端口的模块
            if isempty(targetPorts)
                continue;
            end
            
            % 处理所有目标端口
            for j = 1:length(targetPorts)
                portHandle = targetPorts(j);
                try
                    % 获取连接的信号线
                    lineHandle = get_param(portHandle, 'Line');
                    if lineHandle == -1
                        continue; % 跳过未连接的端口
                    end
                    
                    % 获取当前信号线名称
                    currentName = get_param(lineHandle, 'Name');
                    
                    % 仅当名称不同时设置新名称
                    if isempty(currentName) || ~strcmp(currentName, blockName)
                        set_param(lineHandle, 'Name', blockName);
                        signalNames{end+1} = sprintf('线路: %s (来自模块: %s)', blockName, getfullname(block));
                    else
                        signalNames{end+1} = sprintf('线路: %s (名称已匹配)', blockName);
                    end
                    successCount = successCount + 1;
                    
                catch ME
                    % 仅静默特定命名错误
                    if strcmp(ME.identifier, 'Simulink:Commands:SetParamInvalidArgument')
                        signalNames{end+1} = sprintf('跳过: %s (不支持命名)', blockName);
                        successCount = successCount + 1;
                    else
                        rethrow(ME);
                    end
                end
            end
            
        catch ME
            % 模块级错误重新抛出
            newME = MException('NameTool:BlockProcessing', '模块处理失败 [%s]', block);
            newME = addCause(newME, ME);
            throw(newME);
        end
    end
end