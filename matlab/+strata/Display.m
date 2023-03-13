classdef Display
% Class providing functions for display functionality used in Matlab
% scripts
%
% Functions:
%    positionFigure - Position the current figure in one of 4 quarters of
%                     the screen
%    checkHandles - Check if all items in the provided array are graphics
%                   handles

    methods(Static)
        function positionFigure()
            % Position the current figure in one of 4 quarters of the
            % screen. Call this function after creating a figure. It
            % resizes and moves the figure to fit into the next quarter of
            % the screen in the following sequence: top-left, top-right,
            % bottom-left, bottom-right. Then it starts from the beginning.
            oh = 50;
            ow = 100;

            persistent w;
            persistent h;
            if isempty(w)
                s = get(0, 'ScreenSize');
                w = (s(3) - ow) / 2;
                h = (s(4) - oh) / 2;
            end
            
            f = gcf;
            c = f.Number - 1;
            switch mod(c, 4)
                case 0
                    f.OuterPosition = [ow + 0, oh + h, w, h];
                case 1
                    f.OuterPosition = [ow + w, oh + h, w, h];
                case 2
                    f.OuterPosition = [ow + 0, oh + 0, w, h];
                case 3
                    f.OuterPosition = [ow + w, oh + 0, w, h];
            end
        end
        
        function c = checkHandles(h)
            % Check if all items in the provided array are graphics
            % handles.
            % h: Array of items to check
            % Returns true if yes. If one of the items is no
            % graphics handle, it returns false.
            for i = 1:length(h)
                if ~ishandle(h(i))
                    c = false;
                    return;
                end
            end
            c = true;
        end
    end
end
