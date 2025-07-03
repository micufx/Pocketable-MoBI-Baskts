function save_fig(F, PATHOUT, NAME, varargin)
% save_fig: Save MATLAB figures for publication with specified width and font size
% INPUT:
%     F: figure handle (e.g., gcf)
%     PATHOUT: output directory as a string
%     NAME: filename as a string (no extension)
%     Optional parameters:
%         'fontsize': Minimum font size for all text (default: 8 points)
%         'width_mm': Desired figure width in mm (85 or 180, default: 180 mm)
%         'figtype': File type for saving (default: 'pdf', options: 'pdf', 'eps', 'tiff')
%         'dpi': Resolution for raster images (default: 300 dpi)

% Validate inputs
if ~ischar(PATHOUT) || ~ischar(NAME)
    error('Specify PATHOUT and NAME as strings.');
end

% Parse optional parameters
p = inputParser;
defaultFontSize = 8; % Default font size
defaultWidthMM = 180; % Default width (2-column width)
defaultFigType = 'pdf'; % Default file type
defaultDPI = 600; % Default resolution

addParameter(p, 'fontsize', defaultFontSize, @isnumeric);
addParameter(p, 'width_mm', defaultWidthMM, @(x) isnumeric(x) && (x == 85 || x == 180));
addParameter(p, 'figtype', defaultFigType, @(x) ismember(x, {'pdf', 'eps', 'tiff'}));
addParameter(p, 'dpi', defaultDPI, @isnumeric);

parse(p, varargin{:});
font_s = p.Results.fontsize;
width_mm = p.Results.width_mm;
figtype = p.Results.figtype;
dpi = p.Results.dpi;

% Convert width from mm to cm
width_cm = width_mm / 10;

% Get original figure properties
originalUnits = get(F, 'Units');
set(F, 'Units', 'centimeters');
originalPosition = get(F, 'Position'); % [x, y, width, height]
aspect_ratio = originalPosition(4) / originalPosition(3); % height / width

% Calculate new height to maintain aspect ratio
new_height_cm = width_cm * aspect_ratio;

% Apply new figure dimensions
set(F, 'Position', [originalPosition(1:2), width_cm, new_height_cm]);

% Set figure background to white
set(F, 'Color', 'white');

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

% Save the figure
savePath = fullfile(PATHOUT, [NAME '.' figtype]);

switch figtype
    case 'pdf'
        print(F, savePath, '-dpdf', sprintf('-r%d', dpi)); % Save as PDF
    case 'eps'
        print(F, savePath, '-depsc', sprintf('-r%d', dpi)); % Save as EPS
    case 'tiff'
        print(F, savePath, '-dtiff', sprintf('-r%d', dpi)); % Save as TIFF
end

% Restore original figure units
set(F, 'Units', originalUnits);

% Uncomment to close the figure after saving
% close(F);

end
