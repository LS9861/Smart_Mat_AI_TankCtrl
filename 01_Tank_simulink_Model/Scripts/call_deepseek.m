% call_deepseek.m
% Calls DeepSeek API using API key from .env file

function response = call_deepseek(prompt, varargin)
    % Load API key from .env if not provided
    if nargin < 2 || isempty(varargin{1})
        try
            env = load_env();
            api_key = env.DEEPSEEK_API_KEY;
        catch
            error('API key not found. Set DEEPSEEK_API_KEY in .env file');
        end
    else
        api_key = varargin{1};
    end
    
    % Load API URL from .env or use default
    try
        env = load_env();
        if isfield(env, 'DEEPSEEK_API_URL')
            url = env.DEEPSEEK_API_URL;
        else
            url = 'https://api.deepseek.com/v1/chat/completions';
        end
    catch
        url = 'https://api.deepseek.com/v1/chat/completions';
    end
    
    % Escape special characters
    prompt_escaped = strrep(prompt, '"', '\"');
    prompt_escaped = strrep(prompt_escaped, sprintf('\n'), ' ');
    
    % Build Python command
    cmd = sprintf(['python -c "import requests, json; ' ...
        'r=requests.post(''%s'', ' ...
        'headers={''Authorization'': ''Bearer %s'', ''Content-Type'': ''application/json''}, ' ...
        'json={''model'': ''deepseek-chat'', ''messages'': [{''role'': ''user'', ''content'': ''%s''}], ''max_tokens'': 500}); ' ...
        'print(r.json()[''choices''][0][''message''][''content''])"'], ...
        url, api_key, prompt_escaped);
    
    [status, result] = system(cmd);
    
    if status == 0
        response = strtrim(result);
    else
        error('Python call failed: %s', result);
    end
end