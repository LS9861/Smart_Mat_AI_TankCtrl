% load_env.m
% Load environment variables from .env file
% Usage: load_env()  - loads all variables into workspace
%        key = load_env('DEEPSEEK_API_KEY') - returns specific key

function varargout = load_env(var_name)
    % Find the root directory (where .env file is)
    current_dir = pwd;
    root_dir = current_dir;
    
    % Search up to 5 levels up for .env file
    for i = 1:5
        if exist(fullfile(root_dir, '.env'), 'file')
            break;
        end
        root_dir = fileparts(root_dir);
    end
    
    env_file = fullfile(root_dir, '.env');
    
    if ~exist(env_file, 'file')
        error(['.env file not found in: ' root_dir newline ...
               'Please create .env file with DEEPSEEK_API_KEY=your-key-here']);
    end
    
    % Read .env file
    fid = fopen(env_file, 'r');
    env_vars = struct();
    
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        
        % Skip empty lines and comments
        if isempty(line) || line(1) == '#'
            continue;
        end
        
        % Parse key=value
        eq_idx = strfind(line, '=');
        if ~isempty(eq_idx)
            key = strtrim(line(1:eq_idx(1)-1));
            value = strtrim(line(eq_idx(1)+1:end));
            
            % Remove quotes if present
            if startsWith(value, '"') && endsWith(value, '"')
                value = value(2:end-1);
            end
            if startsWith(value, "'") && endsWith(value, "'")
                value = value(2:end-1);
            end
            
            env_vars.(key) = value;
        end
    end
    fclose(fid);
    
    % Assign to base workspace
    fn = fieldnames(env_vars);
    for i = 1:length(fn)
        assignin('base', fn{i}, env_vars.(fn{i}));
    end
    
    % Return value if requested
    if nargin == 1
        if isfield(env_vars, var_name)
            varargout{1} = env_vars.(var_name);
        else
            error('Variable "%s" not found in .env file', var_name);
        end
    elseif nargout == 1
        varargout{1} = env_vars;
    else
        fprintf('? Loaded %d environment variables:\n', length(fn));
        for i = 1:length(fn)
            % Don't print full API key for security
            if contains(fn{i}, 'API_KEY')
                masked_value = [env_vars.(fn{i})(1:10), '...[HIDDEN]'];
                fprintf('   %s = %s\n', fn{i}, masked_value);
            else
                fprintf('   %s = %s\n', fn{i}, env_vars.(fn{i}));
            end
        end
    end
end