function autoNameSignalLines(namingRule)
% 获取当前系统
sys = gcs;

% 检查参数有效性
if ~exist('namingRule', 'var')
    namingRule = 'source';
end

% 获取所有选中的信号线
selectedLines = find_system(sys,...
    'LookUnderMasks', 'all',...
    'FollowLinks', 'on',...
    'FindAll', 'on',...
    'Type', 'line',...
    'Selected', 'on');

% 处理每条信号线
for i = 1:length(selectedLines)
    try
        lineHandle = selectedLines(i);
        newName = '';
        
        % ===== 根据命名规则获取名称 =====
        if strcmpi(namingRule, 'source')
            % 获取源端口句柄
            srcPortHandle = get(lineHandle, 'SrcPortHandle');
            if isempty(srcPortHandle) || srcPortHandle == -1
                continue;
            end
            
            % 获取源模块和端口号
            srcBlockHandle = get_param(srcPortHandle, 'Parent');
            portNumber = get_param(srcPortHandle, 'PortNumber');
            
            % 检查是否子系统
            if strcmpi(get_param(srcBlockHandle, 'BlockType'), 'SubSystem')
                [~, outputNames] = getPortNames(srcBlockHandle);
                if portNumber <= length(outputNames)
                    newName = outputNames{portNumber};
                end
            % 普通模块获取端口名称
            else
                portName = get_param(srcPortHandle, 'Name');
                if ~isempty(portName)
                    newName = portName;
                end
            end
            
        else % 'destination' 规则
            % 获取目标端口句柄（取第一个）
            dstPortHandles = get(lineHandle, 'DstPortHandle');
            dstPortHandles = dstPortHandles(dstPortHandles ~= -1);
            if isempty(dstPortHandles)
                continue;
            end
            
            % 获取第一个目标端口
            dstPortHandle = dstPortHandles(1);
            dstBlockHandle = get_param(dstPortHandle, 'Parent');
            portNumber = get_param(dstPortHandle, 'PortNumber');
            
            % 检查是否子系统
            if strcmpi(get_param(dstBlockHandle, 'BlockType'), 'SubSystem')
                [inputNames, ~] = getPortNames(dstBlockHandle);
                if portNumber <= length(inputNames)
                    newName = inputNames{portNumber};
                end
            % 普通模块获取端口名称
            else
                portName = get_param(dstPortHandle, 'Name');
                if ~isempty(portName)
                    newName = portName;
                end
            end
        end
        
        % 规范命名（替换非法字符）
        if ~isempty(newName)
            validName = regexprep(newName, '[^\w]', '_'); 
            validName = regexprep(validName, '_{2,}', '_');
            set_param(lineHandle, 'Name', validName);
        end
        
    catch ME
        warning('信号线%d命名失败: %s', i, ME.message);
    end
end
disp(['信号线命名完成! 已处理: ' num2str(length(selectedLines)) ' 条信号线']);
end

%% 辅助函数：获取端口名称（排序版）
function [inputNames, outputNames] = getPortNames(subsystem)
    % 获取输入端口
    inports = find_system(subsystem, 'SearchDepth', 1, 'BlockType', 'Inport');
    inputNames = {};
    if ~isempty(inports)
        % 获取端口号和名称
        portNumbers = zeros(1, length(inports));
        for j = 1:length(inports)
            portNumbers(j) = str2double(get_param(inports{j}, 'Port'));
            inputNames{j} = get_param(inports{j}, 'Name');
        end
        
        % 按端口号排序
        [~, idx] = sort(portNumbers);
        inputNames = inputNames(idx);
    end

    % 获取输出端口（同理）
    outports = find_system(subsystem, 'SearchDepth', 1, 'BlockType', 'Outport');
    outputNames = {};
    if ~isempty(outports)
        portNumbers = zeros(1, length(outports));
        for j = 1:length(outports)
            portNumbers(j) = str2double(get_param(outports{j}, 'Port'));
            outputNames{j} = get_param(outports{j}, 'Name');
        end
        
        [~, idx] = sort(portNumbers);
        outputNames = outputNames(idx);
    end
end