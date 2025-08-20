function autoLinkSubsystemPort(altkey)
model = gcs; % 获取当前模型

% 查找两个子系统
subsystems = find_system(model, 'SearchDepth', 1, 'BlockType', 'SubSystem', 'Selected', 'on');
if numel(subsystems) < 2
    error('需要至少两个选中子系统进行连接');
end
  subsystems=  filterSubsystems(subsystems);
sys1 = subsystems{1}; % 左侧子系统 (先选择)
sys2 = subsystems{2}; % 右侧子系统 (后选择)

% 获取所有端口名称
[in1, out1] = getPortNames(sys1);
[in2, out2] = getPortNames(sys2);

% 连接 sys1输出 → sys2输入
commonPort1 = intersect(out1, in2, 'stable');


% 连接 sys2输出 → sys1输入
commonPort2 = intersect(out2, in1, 'stable');

if altkey
    for i = 1:length(commonPort1)
        connectPorts(sys1, sys2, commonPort1{i});
    end
else
    for i = 1:length(commonPort2)
        connectPorts(sys2, sys1, commonPort2{i});
    end
end

disp('端口连接完成！');

%% 辅助函数：获取端口名称
    function [inputNames, outputNames] = getPortNames(subsystem)
        % 获取输入端口
        inports = find_system(subsystem, 'SearchDepth', 1, 'BlockType', 'Inport');
        inputNames = {};
        if ~isempty(inports)
            if iscell(inports)
                inputNames = get_param(inports, 'Name');
            else
                inputNames = {get_param(inports, 'Name')};
            end
        end

        % 获取输出端口
        outports = find_system(subsystem, 'SearchDepth', 1, 'BlockType', 'Outport');
        outputNames = {};
        if ~isempty(outports)
            if iscell(outports)
                outputNames = get_param(outports, 'Name');
            else
                outputNames = {get_param(outports, 'Name')};
            end
        end
    end

%% 辅助函数：连接端口（核心修复）
    function connectPorts(srcSys, dstSys, portName)
        % 获取源子系统中的输出端口块
        srcPortBlock = find_system(srcSys, 'SearchDepth', 1, 'BlockType', 'Outport', 'Name', portName);
        if isempty(srcPortBlock)
            warning('在源系统中未找到输出端口: %s', portName);
            return;
        end
        srcPortBlock = srcPortBlock{1}; % 取第一个匹配项

        % 获取目标子系统中的输入端口块
        dstPortBlock = find_system(dstSys, 'SearchDepth', 1, 'BlockType', 'Inport', 'Name', portName);
        if isempty(dstPortBlock)
            warning('在目标系统中未找到输入端口: %s', portName);
            return;
        end
        dstPortBlock = dstPortBlock{1};

        % 获取源端口在子系统中的位置
        srcPortNumber = str2double(get_param(srcPortBlock, 'Port'));
        dstPortNumber = str2double(get_param(dstPortBlock, 'Port'));

        % 获取子系统端口句柄
        srcPortHandles = get_param(srcSys, 'PortHandles');
        dstPortHandles = get_param(dstSys, 'PortHandles');

        % 验证端口号
        if srcPortNumber > numel(srcPortHandles.Outport) || srcPortNumber < 1
            warning('源端口号无效: %d', srcPortNumber);
            return;
        end

        if dstPortNumber > numel(dstPortHandles.Inport) || dstPortNumber < 1
            warning('目标端口号无效: %d', dstPortNumber);
            return;
        end

        % 选择正确的端口句柄
        srcPort = srcPortHandles.Outport(srcPortNumber);
        dstPort = dstPortHandles.Inport(dstPortNumber);

        % 创建连接
        try
            add_line(gcs, srcPort, dstPort, 'autorouting', 'smart');
        fprintf('已连接: %s.%s → %s.%s\n', ...
            get_param(srcSys, 'Name'), portName, ...
            get_param(dstSys, 'Name'), portName);
        catch

        end
        
    end
end

function filteredSubsystems = filterSubsystems(subsystems)
% 检查输入是否为空
if isempty(subsystems)
    filteredSubsystems = {};
    return;
end

% 特殊情况：当只有一个元素时直接返回
if numel(subsystems) == 1
    filteredSubsystems = subsystems;
    return;
end

% 检查第一行是否被其他元素包含（作为父级）
parentCandidate = subsystems{1};
shouldRemoveParent = false;

for i = 2:numel(subsystems)
    currentSubsys = subsystems{i};
    
    % 检查当前元素是否包含父级候选（且必须是父级路径）
    if startsWith(currentSubsys, [parentCandidate, '/'])
        shouldRemoveParent = true;
        break; % 找到一个即满足条件
    end
end

% 应用过滤规则
if shouldRemoveParent
    filteredSubsystems = subsystems(2:end);
else
    filteredSubsystems = subsystems;
end
end