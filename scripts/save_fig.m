function save_fig(F, PATHOUT, NAME, varargin)
% save_fig: Enhanced function to save figures with properly adjusted labels
% INPUT:
%     F: figure handle (e.g., gcf)
%     PATHOUT: output directory as a string
%     NAME: filename as a string
%     Optional parameters:
%         'fontsize': Font size for text (default: 8)
%         'figsize': Figure size in cm [width, height] (default: [35, 20])
%         'figtypes': Cell array of file types for saving (default: {'.png'})
%         'dpi': Resolution in dots per inch (default: 300)

% Validate inputs
if ~ischar(PATHOUT) || ~ischar(NAME)
    error('Specify PATHOUT and NAME as strings.');
end

% Parse optional parameters
p = inputParser;
defaultFontSize = 8;
defaultFigSize = [35 20];
defaultFigTypes = {'.png'}; % Default is saving as PNG
defaultDPI = 300;          % Default DPI

addParameter(p, 'fontsize', defaultFontSize, @isnumeric);
addParameter(p, 'figsize', defaultFigSize);
addParameter(p, 'figtypes', defaultFigTypes, @(x) iscell(x) && all(cellfun(@(y) ischar(y), x)));
addParameter(p, 'dpi', defaultDPI, @isnumeric);

parse(p, varargin{:});
font_s = p.Results.fontsize;
fig_s = p.Results.figsize;
figtypes = p.Results.figtypes;
dpi = p.Results.dpi;

% Set figure size
set(F, 'Units', 'centimeters', 'Position', [0 0 fig_s(1) fig_s(2)]);
set(F, 'Color', 'white'); % Set white background

% Adjust all text elements
allText = findall(F, 'Type', 'text');
for i = 1:length(allText)
    set(allText(i), 'FontSize', font_s);
end

% Adjust titles, subtitles, and sgtitle
allTitles = findall(F, 'Type', 'title');
for i = 1:length(allTitles)
    set(allTitles(i), 'FontSize', font_s);
end

% Adjust sgtitle if it exists
sgTitleObj = findobj(F, 'Type', 'sgtitle');
if ~isempty(sgTitleObj)
    set(sgTitleObj, 'FontSize', font_s);
end

% Adjust axes labels, titles, and ticks
allAxes = findall(F, 'Type', 'axes');
for i = 1:length(allAxes)
    xlabelHandle = get(allAxes(i), 'XLabel');
    ylabelHandle = get(allAxes(i), 'YLabel');
    zlabelHandle = get(allAxes(i), 'ZLabel'); % Handle z-axis labels
    titleHandle = get(allAxes(i), 'Title');

    % Adjust labels and titles
    if ~isempty(xlabelHandle)
        set(xlabelHandle, 'FontSize', font_s);
    end
    if ~isempty(ylabelHandle)
        set(ylabelHandle, 'FontSize', font_s);
    end
    if ~isempty(zlabelHandle)
        set(zlabelHandle, 'FontSize', font_s);
    end
    if ~isempty(titleHandle)
        set(titleHandle, 'FontSize', font_s);
    end

    % Adjust tick labels
    set(allAxes(i), 'FontSize', font_s);
end

% Adjust colorbar labels
allColorbars = findall(F, 'Type', 'colorbar');
for i = 1:length(allColorbars)
    set(allColorbars(i), 'FontSize', font_s);
    cbLabel = get(allColorbars(i), 'Label');
    if ~isempty(cbLabel)
        set(cbLabel, 'FontSize', font_s);
    end
end

% Adjust legend fonts
allLegends = findall(F, 'Type', 'legend');
for i = 1:length(allLegends)
    set(allLegends(i), 'FontSize', font_s, 'FontWeight', 'normal');
end

% Save figure in specified formats
for i = 1:length(figtypes)
    figtype = figtypes{i};
    savePath = fullfile(PATHOUT, [NAME figtype]);

    switch lower(figtype)
        case '.png'
            print(F, savePath, '-dpng', ['-r', num2str(dpi)]); % Save as PNG with specified DPI
        case '.svg'
            print(F, savePath, '-dsvg'); % DPI doesn't apply to SVG
        case '.pdf'
            print(F, savePath, '-dpdf', ['-r', num2str(dpi)]); % Save as PDF with specified DPI
        case '.jpg'
            print(F, savePath, '-djpeg', ['-r', num2str(dpi)]); % Save as JPEG with specified DPI
        case '.eps'
            print(F, savePath, '-depsc', ['-r', num2str(dpi)]); % Save as EPS with specified DPI
        case '.tif'
            print(F, savePath, '-depsc', ['-r', num2str(dpi)]); % Save as EPS with specified DPI
        otherwise
            warning('Unsupported file format: %s. Skipping.', figtype);
    end
end

% Uncomment the following line to close the figure after saving
% close(F);

end
