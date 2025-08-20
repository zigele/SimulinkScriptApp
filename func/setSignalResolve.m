% 修改后的setSignalResolve函数 - 返回处理成功的信号线名称列表
function signalNames = setSignalResolve()
    % 获取当前选中的信号线句柄
    selectedLines = find_system(gcs, 'FindAll', 'on', 'Type', 'Line', 'Selected', 'on');
    
    if isempty(selectedLines)
        error('NameTool:NoSelection', '请先选中需要处理的信号线');
    end
    
    % 初始化信号名称容器
    signalNames = cell(1, length(selectedLines));
    validCount = 0;
    
    for i = 1:length(selectedLines)
        % 1. 获取信号线的源端口句柄
        srcPortHandle = get_param(selectedLines(i), 'SrcPortHandle');
        
        % 验证源端口有效性
        if srcPortHandle == -1
            warning('信号线%d没有有效的源端口，已跳过', i);
            continue;
        end
        
        % 2. 获取/创建信号名称
        signalName = get_param(selectedLines(i), 'Name');
        if isempty(signalName)
            % 生成唯一信号名称
            model = bdroot;
            baseName = 'AutoSignal';
            counter = 1;
            signalName = [baseName num2str(counter)];
            
            % 确保名称唯一
            while exist([model '/' signalName], 'var') || ...
                  ~isempty(find_system(model, 'FindAll', 'on', 'Type', 'Line', 'Name', signalName))
                counter = counter + 1;
                signalName = [baseName num2str(counter)];
            end
            set_param(selectedLines(i), 'Name', signalName);
        end
        
        % 3. 设置信号解析属性
        set_param(srcPortHandle, 'MustResolveToSignalObject', 'on');
        
        % 4. 记录成功处理的信号
        validCount = validCount + 1;
        signalNames{validCount} = signalName;
    end
    
    % 返回实际处理的信号名称
    signalNames = signalNames(1:validCount);
end