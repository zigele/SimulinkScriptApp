function autoCreateInOutPorts()
% 获取当前选中的子系统
selectedBlock = gcb;

% 验证选中的是子系统
if ~strcmp(get_param(selectedBlock, 'BlockType'), 'SubSystem')
    error('请先选中一个子系统模块', '无效选择');
    return;
end

% 获取父系统路径
parentSys = get_param(selectedBlock, 'Parent');

% 获取子系统内部所有Inport和Outport模块
inports = find_system(selectedBlock, 'SearchDepth', 1,...
    'BlockType', 'Inport');
outports = find_system(selectedBlock, 'SearchDepth', 1,...
    'BlockType', 'Outport');

% 创建输入端口（基于图片中的AC_Swt_cp）
for i = 1:length(inports)
    portName = get_param(inports{i}, 'Name');

    % 在父系统创建同名输入端口
    if ~exist_block(parentSys, portName)
        % 创建并定位在子系统左侧
        newPos = get_port_position(selectedBlock, 'left', i);
        add_block('built-in/Inport', [parentSys '/' portName],...
            'Position', newPos,'MakeNameUnique', 'on');

        % 连接到子系统的对应端口
        portNum = get_param(inports{i}, 'Port');
        add_line(parentSys, [portName '/1'],...
            [get_param(selectedBlock, 'Name') '/' portNum]);
    else
        % 连接到子系统的对应端口
        try
            portNum = get_param(inports{i}, 'Port');
            add_line(parentSys, [portName '/1'],...
                [get_param(selectedBlock, 'Name') '/' portNum]);
        catch Me

        end
    end
end

% 创建输出端口（基于图片中的AutoSignal1）
for i = 1:length(outports)
    portName = get_param(outports{i}, 'Name');

    % 在父系统创建同名输出端口
    if ~exist_block(parentSys, portName)
        % 创建并定位在子系统右侧
        newPos = get_port_position(selectedBlock, 'right', i);
        add_block('built-in/Outport', [parentSys '/' portName],...
            'Position', newPos,'MakeNameUnique', 'on');

        % 从子系统的对应端口连接
        portNum = get_param(outports{i}, 'Port');
        add_line(parentSys,...
            [get_param(selectedBlock, 'Name') '/' portNum],...
            [portName '/1']);
    else
        % 从子系统的对应端口连接
        try
            portNum = get_param(outports{i}, 'Port');
            add_line(parentSys,...
                [get_param(selectedBlock, 'Name') '/' portNum],...
                [portName '/1']);
        catch Me
        end
    end
end

% 自动布局
Simulink.BlockDiagram.arrangeSystem(parentSys);

end

% 检查父系统中是否已存在同名模块
function exists = exist_block(sys, blockName)
found = find_system(sys, 'SearchDepth', 1,...
    'LookUnderMasks', 'all',...
    'Name', blockName);
exists = ~isempty(found);
end

% 计算端口位置
function pos = get_port_position(subsysBlock, side, index)
subPos = get_param(subsysBlock, 'Position');
spacing = 50;
yOffset = (index - 1) * spacing;

switch side
    case 'left'
        pos = [subPos(1)-100, subPos(2)+yOffset,...
            subPos(1)-30, subPos(2)+yOffset+30];
    case 'right'
        pos = [subPos(3)+30, subPos(2)+yOffset,...
            subPos(3)+100, subPos(2)+yOffset+30];
end
end