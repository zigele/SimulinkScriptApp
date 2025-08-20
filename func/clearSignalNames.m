function clearSignalNames()
% 清除选中信号线的名称
% 无输入参数，直接调用即可

% 获取当前系统
sys = gcs;

% 获取所有选中的信号线
selectedLines = find_system(sys,...
    'LookUnderMasks', 'all',...
    'FollowLinks', 'on',...
    'FindAll', 'on',...
    'Type', 'line',...
    'Selected', 'on');

% 统计处理的信号线数量
clearedCount = 0;

% 处理每条信号线
for i = 1:length(selectedLines)
    try
        lineHandle = selectedLines(i);
        
        % 获取当前信号线名称
        currentName = get_param(lineHandle, 'Name');
        
        % 仅当信号线有名称时才处理
        if ~isempty(currentName)
            % 清除信号线名称
            set_param(lineHandle, 'Name', '');
            clearedCount = clearedCount + 1;
        end
    catch ME
        warning('信号线%d名称清除失败: %s', i, ME.message);
    end
end

% 显示结果
if clearedCount > 0
    disp(['信号线名称清除完成! 已清除: ' num2str(clearedCount) ' 条信号线的名称']);
else
    disp('未找到需要清除名称的选中信号线');
end
end