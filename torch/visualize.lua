
do  
    local Visualize = torch.class('Visualize')

    function Visualize:__init()
        
    end
    function Visualize:plotPoint(im,point,pointSize,color_curr)
        if x>im:size(3) or y>im:size(2) then
            return im;
        end
        local point=torch.Tensor(point);
        local starts=torch.round(point-pointSize/2);
        local ends=torch.round(point+pointSize/2);

        for x_curr=math.max(1,starts[1]),math.min(im:size(3),ends[1]) do
            for y_curr=math.max(1,starts[2]),math.min(im:size(2),ends[2]) do
                for idx_rgb=1,3 do
                    im[idx_rgb][y_curr][x_curr]=color_curr[idx_rgb]/255;            
                end
            end
        end

        return im;

    end

        function Visualize:drawKeyPoints(im,keypoints,scale,colors,pointSize)
        assert (#keypoints:size()==2);
        assert (keypoints:size(1)==2);
        assert (im:size(1)==3);
        
        if not pointSize then
            pointSize=math.max(torch.round(math.min(im:size(2),im:size(3))*0.02),1);
        end
        
        if not colors then
            colors={{255,0,0}};
        end

        -- if torch.max(im)>1 then
        --     im=im/255;
        -- end

        if scale~=nil then
            assert (#scale==2);
            keypoints=keypoints-scale[1];
            keypoints=torch.div(keypoints,scale[2]-scale[1]);
            keypoints[{1,{}}]=keypoints[{1,{}}]*im:size(2);
            keypoints[{2,{}}]=keypoints[{2,{}}]*im:size(3);
        end

        for label_idx=1,keypoints:size(2) do
            x=keypoints[1][label_idx];
            y=keypoints[2][label_idx];
            local color_curr=colors[math.min(#colors,label_idx)];
            im=self:plotPoint(im,{x,y},pointSize,color_curr);
        end

        return im;
    end

    function Visualize:plotLossFigure(losses,losses_iter,val_losses,val_losses_iter,out_file_loss_plot) 
        local ff=gnuplot.pngfigure(out_file_loss_plot)
        -- print (out_file_loss_plot)
        local losses_tensor = torch.Tensor{losses_iter,losses};
        if #val_losses>0 then
            local val_losses_tensor=torch.Tensor{val_losses_iter,val_losses}
            gnuplot.plot({'Train Loss',losses_tensor[1],losses_tensor[2]},{'Val Loss',val_losses_tensor[1],val_losses_tensor[2]});
            gnuplot.grid(true)
        else
            gnuplot.plot({'Train Loss ',losses_tensor[1],losses_tensor[2]});

        end
        gnuplot.title('Losses'..losses_iter[#losses_iter])
        gnuplot.xlabel('Iterations');
        gnuplot.ylabel('Loss');
        gnuplot.plotflush();
        gnuplot.closeall();
        -- gnuplot.pngfigure(out_file_loss_plot);
    end

    function Visualize:plotHist(vals,n_bins,out_file) 
        gnuplot.pngfigure(out_file)
        local str_shape='';
        for idx_size_curr=1,#vals:size() do
            local size_curr = vals:size()[idx_size_curr];

            str_shape=str_shape..' '..size_curr;
        end
        gnuplot.hist(vals:view(vals:nElement()),n_bins)
        gnuplot.title('Parameters'..str_shape)
        gnuplot.xlabel('Values');
        gnuplot.ylabel('Frequency');
        gnuplot.plotflush();
        gnuplot.close();
        -- gnuplot.pngfigure(out_file_loss_plot);
    end


end    

return Visualize;