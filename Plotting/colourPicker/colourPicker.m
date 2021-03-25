function cmap = colourPicker(mapName,varargin)
% Returns a colour map with the user defined values from a wide range of
% useful color maps: Cbrewer, cmocean, matplotlib, Paraview, Colourcet

% Modified by Paul Anderson : 3-3-2021
% This current function was derived from the cmocean matlab function, 
% also using elements from the cbrewer2 matlab function 
%% Copyright and other Author Info 

%%%% Original cmocean author info %%%%
% This function was written by Chad A. Greene of the Institute for Geophysics at the 
% University of Texas at Austin (UTIG), June 2016, using colormaps created by Kristen
% Thyng of Texas A&M University, Department of Oceanography. More information on the
% cmocean project can be found at http://matplotlib.org/cmocean/. 
% cmocean was created by Kristen Thyng. 

%%%% Original cbrewer author info %%%%
%   This product includes color specifications and designs developed by
%   Cynthia Brewer (http://colorbrewer.org/). For more information on
%   ColorBrewer, please visit http://colorbrewer.org/.
%
%   CBREWER2 uses a cached copy of the Cynthia Brewer color schemes which
%   was converted to .mat format by Charles Robert for use with CBREWER.
%   CBREWER is available from the MATLAB FileExchange under the MIT license.


%%%% Original cbrewer2 author/copyright info %%%%
%   Copyright (c) 2016 Scott Lowe
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.

%% Syntax 
% 
%  colourPicker
%  cmap = colourPicker('ColormapName') 
%  cmap = colourPicker('-ColormapName') 
%  cmap = colourPicker(...,NLevels)
%  cmap = colourPicker(...,'pivot',PivotValue) 
%  cmap = colourPicker(...,'negative') 
%  cmap = colourPicker(...,'interpSpace', colourSpace) 
%  cmap = colourPicker(...,'interpMethod', interpType) 

%  colourPicker(...)
%% Description 
% 
% colourPicker without any inputs displays the options for colormaps. 
% 
% cmap = colourPicker('ColormapName') returns a 256x3 colormap. ColormapName can be any of 
% of the following: 
% 
%          SEQUENTIAL:                DIVERGING: 
%          'thermal'                  'balance'
%          'haline'                   'delta'
%          'solar'                    'curl'
%          'ice'                      'diff'
%          'gray'                     'tarn'
%          'oxy' 
%          'deep'                     CONSTANT LIGHTNESS:
%          'dense'                    'phase'
%          'algae'                
%          'matter'                   OTHER:
%          'turbid'                   'topo'
%          'speed'                    
%          'amp'
%          'tempo'
%          'rain'
%
% cmap = colourPicker('-ColormapName') a minus sign preceeding any ColormapName flips the
% order of the colormap. 
%
% cmap = colourPicker(...,NLevels) specifies a number of levels in the colormap.  Default
% value is 256, or the standard number for qualitative colourmaps
%
% cmap = colourPicker(...,'pivot',PivotValue) centers a diverging colormap such that white 
% corresponds to a given value and maximum extents are set using current caxis limits. 
% If no PivotValue is set, 0 is assumed. Early versions of this function used 'zero'
% as the syntax for 'pivot',0 and the old syntax is still supported. 
%
% cmap = colourPicker(...,'negative') inverts the lightness profile of the colormap. This can be 
% useful particularly for divergent colormaps if the default white point of divergence
% gets lost in a white background. 
% 
%  cmap = colourPicker(...,'interpSpace', colourSpace) Allows you to
%  specify a specific colour space within which to perform interpolations
%  Default is 'LAB' = CIELAB, anything else supported by COLORSPACE will also
%  function. See colorspace nested in this function for details

%  cmap = colourPicker(...,'interpMethod', interpType) Allows you to
%  specify an interpolation method. Default is 'cubic', anything available
%  in the builtin interp1 function is available

% colourPicker(...) without any outputs sets the current colormap to the current axes.  
% 
%% Examples - Old needs updataing - PMA 04-03-2021
% Using this sample plot: 
% 
%   imagesc(peaks(1000)+1)
%   colorbar
% 
% Set the colormap to 'algae': 
% 
%   colourPicker('algae') 
% 
% Same as above, but with an inverted algae colormap: 
% 
%   colourPicker('-algae')
% 
% Set the colormap to a 12-level 'solar': 
% 
%   colourPicker('solar',12)
% 
% Get the RGB values of a 5-level thermal colormap: 
% 
%   RGB = colourPicker('thermal',5)
% 
% Some of those values are below zero and others are above. If this dataset represents
% anomalies, perhaps a diverging colormap is more appropriate: 
% 
%   colourPicker('balance') 
% 
% It's unlikely that 1.7776 is an interesting value about which the data values 
% diverge.  If you want to center the colormap on zero using the current color 
% axis limits, simply include the 'pivot' option:  
% 
%   colourPicker('balance','pivot',0) 
%


%% Set list of colormaps
% List of all included colormaps, their type and their origin
%  seq: sequential
%  div: divergent
%  qual: qualitative
%  circ: circula

mapTypes = {...
    'Blues',    'seq'; ... % from cbrewer
    'BuGn',     'seq'; ... % from cbrewer
    'BuPu',     'seq'; ... % from cbrewer
    'GnBu',     'seq'; ... % from cbrewer
    'Greens',   'seq'; ... % from cbrewer
    'Greys',    'seq'; ... % from cbrewer
    'Oranges',  'seq'; ... % from cbrewer
    'OrRd',     'seq'; ... % from cbrewer
    'PuBu',     'seq'; ... % from cbrewer
    'PuBuGn',   'seq'; ... % from cbrewer
    'PuRd',     'seq'; ... % from cbrewer
    'Purples',  'seq'; ... % from cbrewer
    'RdPu',     'seq'; ... % from cbrewer
    'Reds',     'seq'; ... % from cbrewer
    'YlGn',     'seq'; ... % from cbrewer
    'YlGnBu',   'seq'; ... % from cbrewer
    'YlOrBr',   'seq'; ... % from cbrewer
    'YlOrRd',   'seq'; ... % from cbrewer
    'Thermal',  'seq'; ... % from cmocean   
    'Haline',   'seq'; ... % from cmocean
    'Solar',    'seq'; ... % from cmocean
    'Ice',      'seq'; ... % from cmocean
    'Deep',     'seq'; ... % from cmocean
    'Dense',    'seq'; ... % from cmocean
    'Algae',    'seq'; ... % from cmocean
    'Matter',   'seq'; ... % from cmocean
    'Turbid',   'seq'; ... % from cmocean
    'Speed',    'seq'; ... % from cmocean
    'Amp',      'seq'; ... % from cmocean
    'Tempo',    'seq'; ... % from cmocean
    'Rain',     'seq'; ... % from cmocean
    'Viridis',  'seq'; ... % from matplotlib
    'Plasma',   'seq'; ... % from matplotlib
    'Inferno',  'seq'; ... % from matplotlib
    'Magma',    'seq'; ... % from matplotlib
    'Cividis',  'seq'; ... % from matplotlib
    'BrBG',     'div'; ... % from cbrewer
    'PiYG',     'div'; ... % from cbrewer
    'PRGn',     'div'; ... % from cbrewer
    'PuOr',     'div'; ... % from cbrewer
    'RdBu',     'div'; ... % from cbrewer
    'RdGy',     'div'; ... % from cbrewer
    'RdYlBu',   'div'; ... % from cbrewer
    'RdYlGn', 	'div'; ... % from cbrewer
    'Spectral', 'div'; ... % from cbrewer
    'Oxy',      'div'; ... % from cmocean
    'Balance',  'div'; ... % from cmocean
    'Delta',    'div'; ... % from cmocean
    'Topo',     'div'; ... % from cmocean
    'Curl',     'div'; ... % from cmocean
    'Diff',     'div'; ... % from cmocean
    'Tarn',     'div'; ... % from cmocean
    'Accent',   'qual'; ... % from cbrewer
    'Dark2',    'qual'; ... % from cbrewer
    'Paired',   'qual'; ...% from cbrewer
    'Pastel1',  'qual'; ...% from cbrewer
    'Pastel2',  'qual'; ...% from cbrewer
    'Set1',     'qual'; ...% from cbrewer
    'Set2',     'qual'; ...% from cbrewer
    'Set3',     'qual'; ...% from cbrewer
    'Tableau'   'qual'; ... % from tableau
    'Phase'           'circ'; ... % from cmocean
    'ColorSpacious'   'circ'; ... % from CIECAM02 color space/colorspacsious
    'Twilight'        'circ'; ... % from matplotlib
    'TwilightShifted' 'circ'; ... % from matplotlib
    'ColorWheel'      'circ'; ... % from Colorcet
    'CyclicMRY'       'circ'; ... % from Colorcet
    'CyclicMYG'       'circ'; ... % from Colorcet
    'IceFire'         'circ'; ... % from Paraview
    'HSV'             'circ'; ... % from matplotlib
    'HueL60'          'circ'; ... % from Paraview
    'nicEdge'         'circ'; ... % from Paraview
    };

%% Display colormap options: 

if nargin==0
   colourPickerPallete; % This script needs substantial rewriting PMA 04-03-21
   return
end


%% Error checks: 

assert(isnumeric(mapName)==0,'Input error: ColormapName must be a string.') 


%% Parse inputs: 

% Default Values
NLevels = []; % we will set to the size of the colormap or 256 later depending on type 
autopivot = false; 
PivotValue = 0; 
colourSpace = 'LAB';
interpType  = 'pchip';
InvertedColormap = false; 

% Did the user ask for a number of colours?
if ~isempty(varargin)
    NLevels = varargin{1};
end

% Does user want to flip the colormap direction? 
dash = regexp(mapName,'-'); 
if any(dash) 
   InvertedColormap = true; 
   mapName(dash) = []; 
end

% Forgive the Americans ;-) 
if strncmpi(mapName,'gray',4)
   mapName = 'grey'; 
end

% Does the user want a "negative" version of the colormap (with an inverted lightness profile)? 
tmp = strncmpi(varargin,'negative',3); 
if any(tmp) 
   negativeColormap = true; 
   varargin = varargin(~tmp); 
else
   negativeColormap = false; 
end

% Does the user want to center a diverging colormap on a specific value? 
% This parsing support original 'zero' syntax and current 'pivot' syntax. 
 tmp = strncmpi(varargin,'pivot',3) | strncmpi(varargin,'zero',3); % Thanks to Phelype Oleinik for this suggestion. 
 if any(tmp) 
   autopivot = true; 
   try
      if isscalar(varargin{find(tmp)+1})
         PivotValue = varargin{find(tmp)+1}; 
         tmp(find(tmp)+1) = 1; 
      end
   end
   varargin = varargin(~tmp); 
end

% Has user specified a colourspace to transform in? 
tmp = strncmpi(varargin,'interpSpace',7);
if any(tmp) 
   colourSpace = varargin{tmp+1}; 
end

% Has user specified an interpolation method? 
tmp = strncmpi(varargin,'interpMethod',7);
if any(tmp) 
   interpType = varargin{tmp+1}; 
end


%% Set defaults: 
[validColour, colourIdx] = ismember(lower(mapName), lower(mapTypes(:, 1)));

if ~validColour
    error('%s is not a recognised colourmap',mapName);
end

mapName = mapTypes{colourIdx, 1};
mapType = mapTypes{colourIdx, 2};

%% Load RGB values and interpolate to NLevels: 
   cmap = colormapData(mapName); % a seperateFunction provided below with RGB values of all maps.
   
if negativeColormap
   
   if strcmp(mapType,'qual')
       disp('Qualitative maps aren''t designed to have inverted lightness profiles...')
   end
    
   % Convert RGB to LAB colorspace: 
   LAB = colorspace('RGB->LAB',cmap); 

   % Operate on the lightness profile: 
   L = LAB(:,1); 

   % Flip the lightness profile and set the lowest point to black:
   L = max(L) - L; 

   % Stretch the lightness profile to make the lightest bits 95% white. (Going 100% white
   % would make the ends of a divergent profile impossible to distinguish.)
   L = L*(95/max(L)); 

   % Make a new LAB matrix: 
   LAB = [L LAB(:,2:3)]; 
   
   % Convert LAB back to RGB: 
   cmap = colorspace('LAB->RGB',LAB); 
end

% Interpolate if necessary: 
if ~isempty(NLevels) && NLevels~=size(cmap,1)
    
    switch mapType
        case 'qual' % simply replicate the required number of times
            if NLevels < size(cmap,1)
                cmap = cmap(1:NLevels,:);
            else
                disp('Requested more levels than the qualitiative map has... Repeating map');
                repeats = ceil(NLevels./size(cmap,1));
                cmap = repmat(cmap,repeats,1);
                cmap = cmap(1:NLevels,:);
            end
            
        otherwise
        % Convert RGB to chosen colorspace: 
        tempMap = colorspace(['rgb->' colourSpace],cmap);

        % Interpolate using chosen method
        tempMap = interp1(1:size(tempMap,1), tempMap, linspace(1,size(tempMap,1),NLevels),interpType);

        % Convert back to RGB: 
        cmap = colorspace([colourSpace '->RGB'],tempMap); 
    end
end


%% Invert the colormap if requested by user: 

if InvertedColormap
   cmap = flipud(cmap); 
end

%% Adjust values to current caxis limits? 

if autopivot
   clim = caxis; 
   assert(PivotValue>=clim(1) & PivotValue<=clim(2),'Error: pivot value must be within the current color axis limits.') 
   maxval = max(abs(clim-PivotValue)); 
   
   % Convert RGB to chosen colorspace: 
   tempMap = colorspace(['rgb->' colourSpace],cmap);
   tempMap = interp1(linspace(-maxval,maxval,size(tempMap,1))+PivotValue, tempMap, linspace(clim(1),clim(2),size(tempMap,1)),interpType);
   % Convert back to RGB: 
   cmap = colorspace([colourSpace '->RGB'],tempMap); 
end

%% Clean up 

if nargout==0
   colormap(gca,cmap) 
   clear cmap  
end

%%  S U B F U N C T I O N S 


function varargout = colorspace(Conversion,varargin)
%COLORSPACE  Transform a color image between color representations.
%   B = COLORSPACE(S,A) transforms the color representation of image A
%   where S is a string specifying the conversion.  The input array A 
%   should be a real full double array of size Mx3 or MxNx3.  The output B 
%   is the same size as A.
%
%   S tells the source and destination color spaces, S = 'dest<-src', or 
%   alternatively, S = 'src->dest'.  Supported color spaces are
%
%     'RGB'              sRGB IEC 61966-2-1
%     'YCbCr'            Luma + Chroma ("digitized" version of Y'PbPr)
%     'JPEG-YCbCr'       Luma + Chroma space used in JFIF JPEG
%     'YDbDr'            SECAM Y'DbDr Luma + Chroma
%     'YPbPr'            Luma (ITU-R BT.601) + Chroma 
%     'YUV'              NTSC PAL Y'UV Luma + Chroma
%     'YIQ'              NTSC Y'IQ Luma + Chroma
%     'HSV' or 'HSB'     Hue Saturation Value/Brightness
%     'HSL' or 'HLS'     Hue Saturation Luminance
%     'HSI'              Hue Saturation Intensity
%     'XYZ'              CIE 1931 XYZ
%     'Lab'              CIE 1976 L*a*b* (CIELAB)
%     'Luv'              CIE L*u*v* (CIELUV)
%     'LCH'              CIE L*C*H* (CIELCH)
%     'CAT02 LMS'        CIE CAT02 LMS
%
%  All conversions assume 2 degree observer and D65 illuminant.
%
%  Color space names are case insensitive and spaces are ignored.  When 
%  sRGB is the source or destination, it can be omitted. For example 
%  'yuv<-' is short for 'yuv<-rgb'.
%
%  For sRGB, the values should be scaled between 0 and 1.  Beware that 
%  transformations generally do not constrain colors to be "in gamut."  
%  Particularly, transforming from another space to sRGB may obtain 
%  R'G'B' values outside of the [0,1] range.  So the result should be 
%  clamped to [0,1] before displaying:
%     image(min(max(B,0),1));  % Clamp B to [0,1] and display
%
%  sRGB (Red Green Blue) is the (ITU-R BT.709 gamma-corrected) standard
%  red-green-blue representation of colors used in digital imaging.  The 
%  components should be scaled between 0 and 1.  The space can be 
%  visualized geometrically as a cube.
%  
%  Y'PbPr, Y'CbCr, Y'DbDr, Y'UV, and Y'IQ are related to sRGB by linear
%  transformations.  These spaces separate a color into a grayscale
%  luminance component Y and two chroma components.  The valid ranges of
%  the components depends on the space.
%
%  HSV (Hue Saturation Value) is related to sRGB by
%     H = hexagonal hue angle   (0 <= H < 360),
%     S = C/V                   (0 <= S <= 1),
%     V = max(R',G',B')         (0 <= V <= 1),
%  where C = max(R',G',B') - min(R',G',B').  The hue angle H is computed on
%  a hexagon.  The space is geometrically a hexagonal cone.
%
%  HSL (Hue Saturation Lightness) is related to sRGB by
%     H = hexagonal hue angle                (0 <= H < 360),
%     S = C/(1 - |2L-1|)                     (0 <= S <= 1),
%     L = (max(R',G',B') + min(R',G',B'))/2  (0 <= L <= 1),
%  where H and C are the same as in HSV.  Geometrically, the space is a
%  double hexagonal cone.
%
%  HSI (Hue Saturation Intensity) is related to sRGB by
%     H = polar hue angle        (0 <= H < 360),
%     S = 1 - min(R',G',B')/I    (0 <= S <= 1),
%     I = (R'+G'+B')/3           (0 <= I <= 1).
%  Unlike HSV and HSL, the hue angle H is computed on a circle rather than
%  a hexagon. 
%
%  CIE XYZ is related to sRGB by inverse gamma correction followed by a
%  linear transform.  Other CIE color spaces are defined relative to XYZ.
%
%  CIE L*a*b*, L*u*v*, and L*C*H* are nonlinear functions of XYZ.  The L*
%  component is designed to match closely with human perception of
%  lightness.  The other two components describe the chroma.
%
%  CIE CAT02 LMS is the linear transformation of XYZ using the MCAT02 
%  chromatic adaptation matrix.  The space is designed to model the 
%  response of the three types of cones in the human eye, where L, M, S,
%  correspond respectively to red ("long"), green ("medium"), and blue
%  ("short").

% Pascal Getreuer 2005-2010


%%% Input parsing %%%
if nargin < 2, error('Not enough input arguments.'); end
[SrcSpace,DestSpace] = parse(Conversion);

if nargin == 2
   Image = varargin{1};
elseif nargin >= 3
   Image = cat(3,varargin{:});
else
   error('Invalid number of input arguments.');
end

FlipDims = (size(Image,3) == 1);

if FlipDims, Image = permute(Image,[1,3,2]); end
if ~isa(Image,'double'), Image = double(Image)/255; end
if size(Image,3) ~= 3, error('Invalid input size.'); end

SrcT = gettransform(SrcSpace);
DestT = gettransform(DestSpace);

if ~ischar(SrcT) && ~ischar(DestT)
   % Both source and destination transforms are affine, so they
   % can be composed into one affine operation
   T = [DestT(:,1:3)*SrcT(:,1:3),DestT(:,1:3)*SrcT(:,4)+DestT(:,4)];      
   Temp = zeros(size(Image));
   Temp(:,:,1) = T(1)*Image(:,:,1) + T(4)*Image(:,:,2) + T(7)*Image(:,:,3) + T(10);
   Temp(:,:,2) = T(2)*Image(:,:,1) + T(5)*Image(:,:,2) + T(8)*Image(:,:,3) + T(11);
   Temp(:,:,3) = T(3)*Image(:,:,1) + T(6)*Image(:,:,2) + T(9)*Image(:,:,3) + T(12);
   Image = Temp;
elseif ~ischar(DestT)
   Image = rgb(Image,SrcSpace);
   Temp = zeros(size(Image));
   Temp(:,:,1) = DestT(1)*Image(:,:,1) + DestT(4)*Image(:,:,2) + DestT(7)*Image(:,:,3) + DestT(10);
   Temp(:,:,2) = DestT(2)*Image(:,:,1) + DestT(5)*Image(:,:,2) + DestT(8)*Image(:,:,3) + DestT(11);
   Temp(:,:,3) = DestT(3)*Image(:,:,1) + DestT(6)*Image(:,:,2) + DestT(9)*Image(:,:,3) + DestT(12);
   Image = Temp;
else
   Image = feval(DestT,Image,SrcSpace);
end

%%% Output format %%%
if nargout > 1
   varargout = {Image(:,:,1),Image(:,:,2),Image(:,:,3)};
else
   if FlipDims, Image = permute(Image,[1,3,2]); end
   varargout = {Image};
end

return;


function [SrcSpace,DestSpace] = parse(Str)
% Parse conversion argument

if ischar(Str)
   Str = lower(strrep(strrep(Str,'-',''),'=',''));
   k = find(Str == '>');
   
   if length(k) == 1         % Interpret the form 'src->dest'
      SrcSpace = Str(1:k-1);
      DestSpace = Str(k+1:end);
   else
      k = find(Str == '<');
      
      if length(k) == 1      % Interpret the form 'dest<-src'
         DestSpace = Str(1:k-1);
         SrcSpace = Str(k+1:end);
      else
         error(['Invalid conversion, ''',Str,'''.']);
      end   
   end
   
   SrcSpace = alias(SrcSpace);
   DestSpace = alias(DestSpace);
else
   SrcSpace = 1;             % No source pre-transform
   DestSpace = Conversion;
   if any(size(Conversion) ~= 3), error('Transformation matrix must be 3x3.'); end
end
return;


function Space = alias(Space)
Space = strrep(strrep(Space,'cie',''),' ','');

if isempty(Space)
   Space = 'rgb';
end

switch Space
case {'ycbcr','ycc'}
   Space = 'ycbcr';
case {'hsv','hsb'}
   Space = 'hsv';
case {'hsl','hsi','hls'}
   Space = 'hsl';
case {'rgb','yuv','yiq','ydbdr','ycbcr','jpegycbcr','xyz','lab','luv','lch'}
   return;
end
return;


function T = gettransform(Space)
% Get a colorspace transform: either a matrix describing an affine transform,
% or a string referring to a conversion subroutine
switch Space
case 'ypbpr'
   T = [0.299,0.587,0.114,0;-0.1687367,-0.331264,0.5,0;0.5,-0.418688,-0.081312,0];
case 'yuv'
   % sRGB to NTSC/PAL YUV
   % Wikipedia: http://en.wikipedia.org/wiki/YUV
   T = [0.299,0.587,0.114,0;-0.147,-0.289,0.436,0;0.615,-0.515,-0.100,0];
case 'ydbdr'
   % sRGB to SECAM YDbDr
   % Wikipedia: http://en.wikipedia.org/wiki/YDbDr
   T = [0.299,0.587,0.114,0;-0.450,-0.883,1.333,0;-1.333,1.116,0.217,0];
case 'yiq'
   % sRGB in [0,1] to NTSC YIQ in [0,1];[-0.595716,0.595716];[-0.522591,0.522591];
   % Wikipedia: http://en.wikipedia.org/wiki/YIQ
   T = [0.299,0.587,0.114,0;0.595716,-0.274453,-0.321263,0;0.211456,-0.522591,0.311135,0];
case 'ycbcr'
   % sRGB (range [0,1]) to ITU-R BRT.601 (CCIR 601) Y'CbCr
   % Wikipedia: http://en.wikipedia.org/wiki/YCbCr
   % Poynton, Equation 3, scaling of R'G'B to Y'PbPr conversion
   T = [65.481,128.553,24.966,16;-37.797,-74.203,112.0,128;112.0,-93.786,-18.214,128];
case 'jpegycbcr'
   % Wikipedia: http://en.wikipedia.org/wiki/YCbCr
   T = [0.299,0.587,0.114,0;-0.168736,-0.331264,0.5,0.5;0.5,-0.418688,-0.081312,0.5]*255;
case {'rgb','xyz','hsv','hsl','lab','luv','lch','cat02lms'}
   T = Space;
otherwise
   error(['Unknown color space, ''',Space,'''.']);
end
return;


function Image = rgb(Image,SrcSpace)
% Convert to sRGB from 'SrcSpace'
switch SrcSpace
case 'rgb'
   return;
case 'hsv'
   % Convert HSV to sRGB
   Image = huetorgb((1 - Image(:,:,2)).*Image(:,:,3),Image(:,:,3),Image(:,:,1));
case 'hsl'
   % Convert HSL to sRGB
   L = Image(:,:,3);
   Delta = Image(:,:,2).*min(L,1-L);
   Image = huetorgb(L-Delta,L+Delta,Image(:,:,1));
case {'xyz','lab','luv','lch','cat02lms'}
   % Convert to CIE XYZ
   Image = xyz(Image,SrcSpace);
   % Convert XYZ to RGB
   T = [3.2406, -1.5372, -0.4986; -0.9689, 1.8758, 0.0415; 0.0557, -0.2040, 1.057];
   R = T(1)*Image(:,:,1) + T(4)*Image(:,:,2) + T(7)*Image(:,:,3);  % R
   G = T(2)*Image(:,:,1) + T(5)*Image(:,:,2) + T(8)*Image(:,:,3);  % G
   B = T(3)*Image(:,:,1) + T(6)*Image(:,:,2) + T(9)*Image(:,:,3);  % B
   % Desaturate and rescale to constrain resulting RGB values to [0,1]   
   AddWhite = -min(min(min(R,G),B),0);
   R = R + AddWhite;
   G = G + AddWhite;
   B = B + AddWhite;
   % Apply gamma correction to convert linear RGB to sRGB
   Image(:,:,1) = gammacorrection(R);  % R'
   Image(:,:,2) = gammacorrection(G);  % G'
   Image(:,:,3) = gammacorrection(B);  % B'
otherwise  % Conversion is through an affine transform
   T = gettransform(SrcSpace);
   temp = inv(T(:,1:3));
   T = [temp,-temp*T(:,4)];
   R = T(1)*Image(:,:,1) + T(4)*Image(:,:,2) + T(7)*Image(:,:,3) + T(10);
   G = T(2)*Image(:,:,1) + T(5)*Image(:,:,2) + T(8)*Image(:,:,3) + T(11);
   B = T(3)*Image(:,:,1) + T(6)*Image(:,:,2) + T(9)*Image(:,:,3) + T(12);
   Image(:,:,1) = R;
   Image(:,:,2) = G;
   Image(:,:,3) = B;
end

% Clip to [0,1]
Image = min(max(Image,0),1);
return;


function Image = xyz(Image,SrcSpace)
% Convert to CIE XYZ from 'SrcSpace'
WhitePoint = [0.950456,1,1.088754];  

switch SrcSpace
case 'xyz'
   return;
case 'luv'
   % Convert CIE L*uv to XYZ
   WhitePointU = (4*WhitePoint(1))./(WhitePoint(1) + 15*WhitePoint(2) + 3*WhitePoint(3));
   WhitePointV = (9*WhitePoint(2))./(WhitePoint(1) + 15*WhitePoint(2) + 3*WhitePoint(3));
   L = Image(:,:,1);
   Y = (L + 16)/116;
   Y = invf(Y)*WhitePoint(2);
   U = Image(:,:,2)./(13*L + 1e-6*(L==0)) + WhitePointU;
   V = Image(:,:,3)./(13*L + 1e-6*(L==0)) + WhitePointV;
   Image(:,:,1) = -(9*Y.*U)./((U-4).*V - U.*V);                  % X
   Image(:,:,2) = Y;                                             % Y
   Image(:,:,3) = (9*Y - (15*V.*Y) - (V.*Image(:,:,1)))./(3*V);  % Z
case {'lab','lch'}
   Image = lab(Image,SrcSpace);
   % Convert CIE L*ab to XYZ
   fY = (Image(:,:,1) + 16)/116;
   fX = fY + Image(:,:,2)/500;
   fZ = fY - Image(:,:,3)/200;
   Image(:,:,1) = WhitePoint(1)*invf(fX);  % X
   Image(:,:,2) = WhitePoint(2)*invf(fY);  % Y
   Image(:,:,3) = WhitePoint(3)*invf(fZ);  % Z
case 'cat02lms'
    % Convert CAT02 LMS to XYZ
   T = inv([0.7328, 0.4296, -0.1624;-0.7036, 1.6975, 0.0061; 0.0030, 0.0136, 0.9834]);
   L = Image(:,:,1);
   M = Image(:,:,2);
   S = Image(:,:,3);
   Image(:,:,1) = T(1)*L + T(4)*M + T(7)*S;  % X 
   Image(:,:,2) = T(2)*L + T(5)*M + T(8)*S;  % Y
   Image(:,:,3) = T(3)*L + T(6)*M + T(9)*S;  % Z
otherwise   % Convert from some gamma-corrected space
   % Convert to sRGB
   Image = rgb(Image,SrcSpace);
   % Undo gamma correction
   R = invgammacorrection(Image(:,:,1));
   G = invgammacorrection(Image(:,:,2));
   B = invgammacorrection(Image(:,:,3));
   % Convert RGB to XYZ
   T = inv([3.2406, -1.5372, -0.4986; -0.9689, 1.8758, 0.0415; 0.0557, -0.2040, 1.057]);
   Image(:,:,1) = T(1)*R + T(4)*G + T(7)*B;  % X 
   Image(:,:,2) = T(2)*R + T(5)*G + T(8)*B;  % Y
   Image(:,:,3) = T(3)*R + T(6)*G + T(9)*B;  % Z
end
return;


function Image = hsv(Image,SrcSpace)
% Convert to HSV
Image = rgb(Image,SrcSpace);
V = max(Image,[],3);
S = (V - min(Image,[],3))./(V + (V == 0));
Image(:,:,1) = rgbtohue(Image);
Image(:,:,2) = S;
Image(:,:,3) = V;
return;


function Image = hsl(Image,SrcSpace)
% Convert to HSL 
switch SrcSpace
case 'hsv'
   % Convert HSV to HSL   
   MaxVal = Image(:,:,3);
   MinVal = (1 - Image(:,:,2)).*MaxVal;
   L = 0.5*(MaxVal + MinVal);
   temp = min(L,1-L);
   Image(:,:,2) = 0.5*(MaxVal - MinVal)./(temp + (temp == 0));
   Image(:,:,3) = L;
otherwise
   Image = rgb(Image,SrcSpace);  % Convert to sRGB
   % Convert sRGB to HSL
   MinVal = min(Image,[],3);
   MaxVal = max(Image,[],3);
   L = 0.5*(MaxVal + MinVal);
   temp = min(L,1-L);
   S = 0.5*(MaxVal - MinVal)./(temp + (temp == 0));
   Image(:,:,1) = rgbtohue(Image);
   Image(:,:,2) = S;
   Image(:,:,3) = L;
end
return;


function Image = lab(Image,SrcSpace)
% Convert to CIE L*a*b* (CIELAB)
WhitePoint = [0.950456,1,1.088754];

switch SrcSpace
case 'lab'
   return;
case 'lch'
   % Convert CIE L*CH to CIE L*ab
   C = Image(:,:,2);
   Image(:,:,2) = cos(Image(:,:,3)*pi/180).*C;  % a*
   Image(:,:,3) = sin(Image(:,:,3)*pi/180).*C;  % b*
otherwise
   Image = xyz(Image,SrcSpace);  % Convert to XYZ
   % Convert XYZ to CIE L*a*b*
   X = Image(:,:,1)/WhitePoint(1);
   Y = Image(:,:,2)/WhitePoint(2);
   Z = Image(:,:,3)/WhitePoint(3);
   fX = f(X);
   fY = f(Y);
   fZ = f(Z);
   Image(:,:,1) = 116*fY - 16;    % L*
   Image(:,:,2) = 500*(fX - fY);  % a*
   Image(:,:,3) = 200*(fY - fZ);  % b*
end
return;


function Image = luv(Image,SrcSpace)
% Convert to CIE L*u*v* (CIELUV)
WhitePoint = [0.950456,1,1.088754];
WhitePointU = (4*WhitePoint(1))./(WhitePoint(1) + 15*WhitePoint(2) + 3*WhitePoint(3));
WhitePointV = (9*WhitePoint(2))./(WhitePoint(1) + 15*WhitePoint(2) + 3*WhitePoint(3));

Image = xyz(Image,SrcSpace); % Convert to XYZ
Denom = Image(:,:,1) + 15*Image(:,:,2) + 3*Image(:,:,3);
U = (4*Image(:,:,1))./(Denom + (Denom == 0));
V = (9*Image(:,:,2))./(Denom + (Denom == 0));
Y = Image(:,:,2)/WhitePoint(2);
L = 116*f(Y) - 16;
Image(:,:,1) = L;                        % L*
Image(:,:,2) = 13*L.*(U - WhitePointU);  % u*
Image(:,:,3) = 13*L.*(V - WhitePointV);  % v*
return;  


function Image = lch(Image,SrcSpace)
% Convert to CIE L*ch
Image = lab(Image,SrcSpace);  % Convert to CIE L*ab
H = atan2(Image(:,:,3),Image(:,:,2));
H = H*180/pi + 360*(H < 0);
Image(:,:,2) = sqrt(Image(:,:,2).^2 + Image(:,:,3).^2);  % C
Image(:,:,3) = H;                                        % H
return;


function Image = cat02lms(Image,SrcSpace)
% Convert to CAT02 LMS
Image = xyz(Image,SrcSpace);
T = [0.7328, 0.4296, -0.1624;-0.7036, 1.6975, 0.0061; 0.0030, 0.0136, 0.9834];
X = Image(:,:,1);
Y = Image(:,:,2);
Z = Image(:,:,3);
Image(:,:,1) = T(1)*X + T(4)*Y + T(7)*Z;  % L
Image(:,:,2) = T(2)*X + T(5)*Y + T(8)*Z;  % M
Image(:,:,3) = T(3)*X + T(6)*Y + T(9)*Z;  % S
return;


function Image = huetorgb(m0,m2,H)
% Convert HSV or HSL hue to RGB
N = size(H);
H = min(max(H(:),0),360)/60;
m0 = m0(:);
m2 = m2(:);
F = H - round(H/2)*2;
M = [m0, m0 + (m2-m0).*abs(F), m2];
Num = length(m0);
j = [2 1 0;1 2 0;0 2 1;0 1 2;1 0 2;2 0 1;2 1 0]*Num;
k = floor(H) + 1;
Image = reshape([M(j(k,1)+(1:Num).'),M(j(k,2)+(1:Num).'),M(j(k,3)+(1:Num).')],[N,3]);
return;


function H = rgbtohue(Image)
% Convert RGB to HSV or HSL hue
[M,i] = sort(Image,3);
i = i(:,:,3);
Delta = M(:,:,3) - M(:,:,1);
Delta = Delta + (Delta == 0);
R = Image(:,:,1);
G = Image(:,:,2);
B = Image(:,:,3);
H = zeros(size(R));
k = (i == 1);
H(k) = (G(k) - B(k))./Delta(k);
k = (i == 2);
H(k) = 2 + (B(k) - R(k))./Delta(k);
k = (i == 3);
H(k) = 4 + (R(k) - G(k))./Delta(k);
H = 60*H + 360*(H < 0);
H(Delta == 0) = nan;
return;


function Rp = gammacorrection(R)
Rp = zeros(size(R));
i = (R <= 0.0031306684425005883);
Rp(i) = 12.92*R(i);
Rp(~i) = real(1.055*R(~i).^0.416666666666666667 - 0.055);
return;


function R = invgammacorrection(Rp)
R = zeros(size(Rp));
i = (Rp <= 0.0404482362771076);
R(i) = Rp(i)/12.92;
R(~i) = real(((Rp(~i) + 0.055)/1.055).^2.4);
return;


function fY = f(Y)
fY = real(Y.^(1/3));
i = (Y < 0.008856);
fY(i) = Y(i)*(841/108) + (4/29);
return;


function Y = invf(fY)
Y = fY.^3;
i = (Y < 0.008856);
Y(i) = (fY(i) - 4/29)*(108/841);
return;