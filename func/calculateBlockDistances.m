function [minVerticalDistance, minHorizontalDistance] = calculateBlockDistances()
    % 获取当前选中的非子系统模块
    selectedBlocks = find_system(gcs, 'SearchDepth', 1, 'LookUnderMasks', 'none', ...
        'FollowLinks', 'off', 'type', 'block', 'Selected', 'on');
    
    % 过滤掉子系统模块 (BlockType为'SubSystem')
    selectedBlocks = selectedBlocks(~strcmp(get_param(selectedBlocks, 'BlockType'), 'SubSystem'));
    
    % 检查选中数量
    if numel(selectedBlocks) ~= 2
        error('BlockDistance:InvalidSelection', '请选择两个非子系统模块');
    end
    
    % 获取模块位置信息 (保持不变)
    pos1 = get_param(selectedBlocks{1}, 'Position');
    pos2 = get_param(selectedBlocks{2}, 'Position');
    
    % 提取边界坐标 (格式: [左x1, 上y1, 右x3, 下y4])
    x1a = pos1(1); y1a = pos1(2); x3a = pos1(3); y4a = pos1(4);
    x1b = pos2(1); y1b = pos2(2); x3b = pos2(3); y4b = pos2(4);
    
    % ===== 计算所有垂直边之间的水平距离 =====
    horizontalDistances = [x1b - x3a,   % 右→左
                           x1a - x3b,   % 左→右
                           x3b - x3a,   % 右→右
                           x1b - x1a];  % 左→左
    
    % 找出绝对值最小的水平距离（保留符号）
    [~, idx] = min(abs(horizontalDistances));
    minHorizontalDistance = horizontalDistances(idx);
    
    % ===== 计算所有水平边之间的垂直距离 =====
    verticalDistances = [y1b - y4a,   % 下→上
                         y1a - y4b,   % 上→下
                         y4b - y4a,   % 下→下
                         y1b - y1a];  % 上→上
    
    % 找出绝对值最小的垂直距离（保留符号）
    [~, idx] = min(abs(verticalDistances));
    minVerticalDistance = verticalDistances(idx);
end