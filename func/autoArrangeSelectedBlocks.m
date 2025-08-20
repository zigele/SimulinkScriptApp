function blockNames = autoArrangeSelectedBlocks(verticalSpacing)
    % 获取当前模型和选中状态
    try
        % 方法1：优先使用find_system获取选中模块（推荐）
        selectedBlocks = find_system(gcs, 'FindAll', 'on', 'Type', 'block', 'Selected', 'on');
    catch
        error('无法获取选中模块，请确保模型已打开且有模块被选中');
    end
    if ~exist("verticalSpacing")
        verticalSpacing=21;
    end
    % 排除子系统类型的模块
    isNotSubsystem = arrayfun(@(x) ~strcmp(get_param(x, 'BlockType'), 'SubSystem'), selectedBlocks);
    selectedBlocks = selectedBlocks(isNotSubsystem);
    
    % 检查是否有选中的模块
    if isempty(selectedBlocks)
        error('没有选中的非子系统模块。请先在Simulink图中选中要排列的基本模块');
    end
    
    % 设置排列参数（根据您的图片优化）
    alignMode = 'center';   % 对齐方式: center/left/right
    
    % 获取模块位置信息并排序
    positions = arrayfun(@(x) get_param(x, 'Position'), selectedBlocks, 'UniformOutput', false);
    heights = cellfun(@(x) x(4)-x(2), positions);
    widths = cellfun(@(x) x(3)-x(1), positions);
    y_positions = cellfun(@(x) x(2), positions);
    
    % 按Y坐标排序（从上到下）
    [~, order] = sort(y_positions);
    selectedBlocks = selectedBlocks(order);
    heights = heights(order);
    widths = widths(order);
    
    % 计算参考位置
    first_pos = get_param(selectedBlocks(1), 'Position');
    refY = first_pos(2);  % 起始Y坐标
    
    % 排列模块
    for i = 1:length(selectedBlocks)
        curPos = get_param(selectedBlocks(i), 'Position');
        
        % 计算新Y位置
        newY = refY;
        newBottom = newY + heights(i);
        
        % 水平对齐处理
        switch alignMode
            case 'left'
                newX = min(cellfun(@(x) x(1), positions));
            case 'center'
                % 使用当前模块宽度重新计算中心对齐
                newX = curPos(1) + (curPos(3)-curPos(1))/2 - widths(i)/2;
            case 'right'
                newX = max(cellfun(@(x) x(3), positions)) - widths(i);
            otherwise
                newX = curPos(1); % 保持原X位置
        end
        
        % 设置新位置
        newPos = [newX, newY, newX+widths(i), newBottom];
        set_param(selectedBlocks(i), 'Position', newPos);
        
        % 更新Y坐标（为下一个模块）
        refY = newBottom + verticalSpacing;
    end
    
    % 格式化显示结果
    blockNames = arrayfun(@(x) get_param(x, 'Name'), selectedBlocks, 'UniformOutput', false);
end