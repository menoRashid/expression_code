
do  
    local data = torch.class('data_face')

    function data:__init(args)
        print ('MEAN FIRST');
        self.file_path=args.file_path;
        self.batch_size=args.batch_size;
        self.limit=args.limit;
        self.augmentation=args.augmentation;
        self.twoClass=args.twoClass;        
        print ('self.augmentation',self.augmentation);

        self.start_idx_face=1;
        self.input_size={256,256};
        if args.input_size then
            self.input_size=args.input_size
        end
        self.crop_size={224,224};
        if args.crop_size then
            self.crop_size=args.crop_size
        end
        
        self.bgr=true;
        
        self.angles={-10,10};
        self.crop_size={224,224};
        self.scale={0.7,1.4};
        -- self.a_range = {0.25,4}
        -- self.b_range = {0.1,1};
        
        self.ratio_blur=args.ratio_blur;
        self.activation_upper=args.activation_upper;

        -- set blurring parameters and nets
        self.net=args.net;
        self.net_gb=args.net_gb;
        self.conv_size=args.conv_size
        if self.conv_size then
            self.gauss_layer,self.gauss_layer_small,self.up_layer,self.min_layer,self.max_layer=self:getHelperNets(2*self.conv_size+1,self.conv_size)
        end

        -- optimize flag
        self.optimize=args.optimize;
        self.mean={122.67891434,116.66876762,104.00698793}

        self.training_set={};
        self.lines_face=self:readDataFile(self.file_path);
        
        if self.augmentation then
            self.lines_face =self:shuffleLines(self.lines_face);
        end

        if self.limit~=nil then
            local lines_face=self.lines_face;
            self.lines_face={};

            for i=1,self.limit do
                self.lines_face[#self.lines_face+1]=lines_face[i];
            end
        end

        if self.optimize then
            print ('OPTIMIZING');
            self.training_images,self.training_labels,self.lines_face = self:loadTrainingImages();
            print (self.training_images:size());
            print (self.training_labels:size());
        end

        print (#self.lines_face);
        
    end


    function data:loadTrainingImages()
        print ('self.input_size',self.input_size);
        local im_all=torch.zeros(#self.lines_face,3,self.input_size[1]
            ,self.input_size[2]);
        local labels = torch.zeros(#self.lines_face);
        local lines_face={};

        local curr_idx=0
        for line_idx=1,#self.lines_face do
            local img_path_face=self.lines_face[line_idx][1];
            local label_face=self.lines_face[line_idx][2];
            local status_img_face,img_face=pcall(image.load,img_path_face);
            if status_img_face then
                curr_idx=curr_idx+1;
                if img_face:size(2)~=self.input_size[1] then 
                    img_face = image.scale(img_face,self.input_size[1],self.input_size[2]);
                end
                im_all[curr_idx]=img_face;
                labels[curr_idx]=label_face;
                lines_face[curr_idx]=self.lines_face[line_idx];
            end
        end
        return im_all,labels,lines_face     
    end

    function data:getGCamEtc(net,net_gb,layer_to_viz,batch_inputs,batch_targets,also_pred)
        net:zeroGradParameters();
        net_gb:zeroGradParameters();
        local outputs=net:forward(batch_inputs);
        local scores, pred_labels = torch.max(outputs, 2);
        pred_labels = pred_labels:type(batch_targets:type());
        pred_labels = pred_labels:view(batch_targets:size());
        local outputs_gb= net_gb:forward(batch_inputs);
        local doutput_gt =  utils.create_grad_input_batch(net.modules[#net.modules], batch_targets)
        local gcam_gt = utils.grad_cam_batch(net, layer_to_viz, doutput_gt):clone();
        local gb_viz_gt = net_gb:backward(batch_inputs, doutput_gt):clone()

        local gcam_pred,gb_viz_pred
        if also_pred then
            net:zeroGradParameters();
            net_gb:zeroGradParameters();
            local doutput_pred = utils.create_grad_input_batch(net.modules[#net.modules], pred_labels)
            gcam_pred = utils.grad_cam_batch(net, layer_to_viz, doutput_pred):clone();
            gb_viz_pred = net_gb:backward(batch_inputs, doutput_pred):clone()
        else
            gcam_pred=nil;
            gb_viz_pred=nil;
        end
        net:clearState();
        net_gb:clearState();
        return {gcam_pred,gcam_gt},{gb_viz_pred,gb_viz_gt},pred_labels
        -- return {gcam_gt,gcam_gt},{gb_viz_gt,gb_viz_gt},pred_labels;
        
    end

    function data:getHelperNets(conv_size_blur,conv_size_mask)
        -- build helper nets for blurring and min maxing with cuda
        -- local gauss_big = image.gaussian({height=conv_size_blur,width=conv_size_blur,normalize=true});
        -- local gauss_real = torch.zeros(3,3,conv_size_blur,conv_size_blur);
        -- for i=1,3 do
        --     gauss_real[{i,i,{},{}}]=gauss_big;
        -- end
        -- local gauss_layer= nn.SpatialConvolution(3,3,conv_size_blur,conv_size_blur,
        --                                         1,1,(conv_size_blur-1)/2,(conv_size_blur-1)/2):cuda();
        -- gauss_layer.weight=gauss_real:cuda();
        -- -- gauss_big:view(1,1,gauss_big:size(1),gauss_big:size(2)):clone()
        -- gauss_layer.bias:fill(0);
        
        local gauss =  image.gaussian({height=conv_size_mask,width=conv_size_mask,normalize=true})
        local gauss_real = torch.zeros(3,3,conv_size_mask,conv_size_mask);
        for i=1,3 do
            gauss_real[{i,i,{},{}}]=gauss;
        end
        -- gauss=torch.repeatTensor(gauss:view(1,1,gauss:size(1),gauss:size(2)),3,3,1,1):cuda()
        -- print ('gauss',gauss:size());
        local gauss_layer_small = nn.SpatialConvolution(3,3,conv_size_mask,conv_size_mask,
                                                1,1,(conv_size_mask-1)/2,(conv_size_mask-1)/2):cuda();
        -- print (gauss_layer_small.weight:size())
        -- print (gauss:view(1,gauss:size(1),gauss:size(2),gauss:size(3)):size())
        gauss_layer_small.weight = gauss_real:cuda();
        -- gauss:view(1,gauss:size(1),gauss:size(2),gauss:size(3)):clone()
        gauss_layer_small.bias:fill(0);
        
        local up_layer = nn.SpatialUpSamplingBilinear({oheight=self.crop_size[1],owidth=self.crop_size[2]}):cuda();

        local min_layer = nn.Sequential();
        min_layer:add(nn.Min(3,3));
        min_layer:add(nn.Min(2,2));
        min_layer:add(nn.Replicate(self.crop_size[2],3));
        min_layer:add(nn.Replicate(self.crop_size[1],4));
        min_layer = min_layer:cuda();

        local max_layer = nn.Sequential();
        max_layer:add(nn.Max(3,3));
        max_layer:add(nn.Max(2,2));
        max_layer:add(nn.Replicate(self.crop_size[2],3));
        max_layer:add(nn.Replicate(self.crop_size[1],4));
        max_layer = max_layer:cuda();        
        
        return gauss_layer,gauss_layer_small,up_layer,min_layer,max_layer;
    end

    function data:getMeanBlurredImages(inputs_org,min_vals,max_vals,gcam_curr,gb_viz_curr,activation_thresh,strategy,bin_keep);
        -- print ('scheme',strategy);
        local gauss_layer_small = self.gauss_layer_small;
        local up_layer = self.up_layer;
        local min_layer = self.min_layer;
        local max_layer = self.max_layer;
        
        -- get activations

        gcam_curr = up_layer:forward(gcam_curr):clone();
        gcam_curr = torch.repeatTensor(gcam_curr,1,3,1,1);
        -- torch.cat(gcam_curr,gcam_curr,1):cat(gcam_curr,1)
        -- print (gcam_curr:size(),gb_viz_curr:size());
        local gb_gcam_org_all = torch.cmul(gb_viz_curr,gcam_curr);
        local gb_gcam_all = torch.abs(gb_gcam_org_all);
        gb_gcam_all:cdiv(max_layer:forward(gb_gcam_all:csub(min_layer:forward(gb_gcam_all))));
        
        gb_gcam_all=torch.sum(gb_gcam_all,2)/gb_gcam_all:size(2);
        local gb_gcam_th_all =torch.zeros(gb_gcam_all:size()):type(gb_gcam_all:type());
        local vals_all = gb_gcam_th_all:clone();
    
        local im_num_end_blur=inputs_org:size(1);
        local max_val = torch.max(gb_gcam_all);
        if self.ratio_blur then
            im_num_end_blur=inputs_org:size(1)*self.ratio_blur;
        end
        
        local num_eff_blurred=math.min(torch.sum(bin_keep),im_num_end_blur);
        local num_blurred=0;
        
        for im_num =1, inputs_org:size(1) do
            if bin_keep[im_num]==1 and num_blurred<im_num_end_blur then
                -- print ('blurring');
                num_blurred=num_blurred+1;
                local activation_thresh_curr;
                
                if strategy=='ncl' then
                    activation_thresh_curr=activation_thresh;
                elseif strategy=='mix' then
                    activation_thresh_curr=self.activation_upper[torch.random(self.activation_upper:nElement())];
                elseif strategy=='mixcl' then
                    if num_blurred<=(num_eff_blurred/2) then
                        activation_thresh_curr=self.activation_upper[torch.random(self.activation_upper:nElement())];
                    else
                        activation_thresh_curr=activation_thresh;
                    end
                end
                
                local gb_gcam = gb_gcam_all[im_num][1];
                -- torch.sum(gb_gcam_all[im_num],1)/gb_gcam_all:size(2);
                local gb_gcam_vals = torch.sort(gb_gcam:view(-1),1,true);
                local idx_gb_gcam_vals=math.floor(gb_gcam_vals:size(1)*activation_thresh_curr)
                
                idx_gb_gcam_vals=math.max(1,idx_gb_gcam_vals);
                
                local val = gb_gcam_vals[idx_gb_gcam_vals];
                vals_all[im_num]:fill(val);
            else
                vals_all[im_num]:fill(max_val+1);
            end
        end

        -- create masks and blur
        gb_gcam_th_all[gb_gcam_all:ge(vals_all)]=1;
        gb_gcam_th_all[gb_gcam_all:lt(vals_all)]=0;
        gb_gcam_th_all=torch.repeatTensor(gb_gcam_th_all,1,3,1,1)
        
        gb_gcam_th_all=gauss_layer_small:forward(gb_gcam_th_all):clone();
        gb_gcam_th_all:cdiv(max_layer:forward(gb_gcam_th_all:csub(min_layer:forward(gb_gcam_th_all))));
        gb_gcam_th_all[gb_gcam_th_all:ne(gb_gcam_th_all)]=0;
        -- gb_gcam_th_all[gb_gcam_th_all:gt(0)]=1;
        

        -- blur specific parts in input image
        local im_blur_all=inputs_org:clone();
        im_blur_all:cmul(max_vals);
        im_blur_all=im_blur_all+min_vals;
        im_blur_all=torch.cmul((1-gb_gcam_th_all),im_blur_all);

        gauss_layer_small:clearState();
        up_layer:clearState();
        min_layer:clearState();
        max_layer:clearState();

        return im_blur_all,gcam_curr,gb_gcam_all,gb_gcam_org_all,gb_gcam_th_all;
    end

    function data:unMean(inputs)
        local inputs_clone=inputs:clone();
        if self.bgr then
            inputs_clone[{{},1,{},{}}]=inputs[{{},3,{},{}}]
            inputs_clone[{{},3,{},{}}]=inputs[{{},1,{},{}}]
        end
        for i=1,3 do
            inputs_clone[{{},i,{},{}}]=inputs_clone[{{},i,{},{}}]+self.mean[i];
        end
        return inputs_clone;
    end

    function data:buildBlurryBatch(layer_to_viz,activation_thresh,strategy,out_file_pre,also_pred)
        
        local train_state=self.net.train;
        
        if self.net:type()~='torch.CudaTensor' then
            self.net=self.net:cuda();
        end
        
        if self.net_gb:type()~='torch.CudaTensor' then
            self.net_gb=self.net_gb:cuda();
        end
        
        if train_state then
            self.net:evaluate();
            self.net_gb:evaluate();
        end

        -- build a batch of images mean preprocessed before augmentation
        self:getTrainingData();
        
        -- set cuda
        self.training_set.data = self.training_set.data:cuda();
        self.training_set.label = self.training_set.label:cuda();
        local batch_inputs = self.training_set.data;
        local batch_targets = self.training_set.label;
        
        -- get gcam stuff
        local gcam_both,gb_viz_both,pred_labels = self:getGCamEtc(self.net,self.net_gb,layer_to_viz,batch_inputs,batch_targets,also_pred)
        
        local bin_keep=pred_labels:eq(batch_targets);

        -- set input range 0-1
        local inputs_org=batch_inputs;
        local min_vals=self.min_layer:forward(inputs_org):clone();

        inputs_org=inputs_org-min_vals;
        local max_vals=self.max_layer:forward(inputs_org):clone();
        inputs_org:cdiv(max_vals);
        
        local im_blur_all,gcam_curr,gb_gcam_all,gb_gcam_org_all,gb_gcam_th_all=self:getMeanBlurredImages(inputs_org,min_vals,max_vals,gcam_both[2],gb_viz_both[2],activation_thresh,strategy,bin_keep)
        local im_blur_all_pred,gcam_curr_pred,gb_gcam_all_pred,gb_gcam_org_all_pred,gb_gcam_th_all_pred;
        if also_pred then
            im_blur_all_pred,gcam_curr_pred,gb_gcam_all_pred,gb_gcam_org_all_pred,gb_gcam_th_all_pred=self:getMeanBlurredImages(inputs_org,min_vals,max_vals,gcam_both[1],gb_viz_both[1],activation_thresh,strategy,bin_keep)
        end

        
        self.training_set.data = im_blur_all;
        self.training_set.label = batch_targets;
        
        if out_file_pre then
            inputs_org=inputs_org:cmul(max_vals)+min_vals
            inputs_org=self:unMean(inputs_org);
            
            for im_num=1,inputs_org:size(1) do
                local out_file_org=out_file_pre..im_num..'_org.jpg';
                local out_file_gb_gcam=out_file_pre..im_num..'_gb_gcam.jpg';
                -- local out_file_hm=out_file_pre..im_num..'_hm.jpg';
                local out_file_gb_gcam_org=out_file_pre..im_num..'_gb_gcam_org.jpg';
                local out_file_gb_gcam_th=out_file_pre..im_num..'_gb_gcam_th.jpg';
                local out_file_g = out_file_pre..im_num..'_gaussian.jpg';
                local out_file_blur = out_file_pre..im_num..'_blur.jpg';
                local gcam=gcam_curr[im_num]
                local gb_gcam = gb_gcam_all[im_num];
                local gb_gcam_org = gb_gcam_org_all[im_num]
                -- local hm = utils.to_heatmap(gcam:float())
                local im_org = inputs_org[im_num][1];
                local gb_gcam_th = gb_gcam_th_all[im_num][1];
                local im_blur = im_blur_all[im_num][1]

                
                image.save(out_file_blur,image.toDisplayTensor(im_blur));
                image.save(out_file_gb_gcam_th, image.toDisplayTensor(gb_gcam_th))
                image.save(out_file_gb_gcam, image.toDisplayTensor(gb_gcam))
                image.save(out_file_gb_gcam_org, image.toDisplayTensor(gb_gcam_org))
                -- image.save(out_file_hm, image.toDisplayTensor(hm))
                image.save(out_file_org, image.toDisplayTensor(im_org))
                
                if also_pred then
                    local out_file_gb_gcam_pred=out_file_pre..im_num..'_gb_gcam_pred.jpg';
                    -- local out_file_hm_pred=out_file_pre..im_num..'_hm_pred.jpg';
                    local out_file_gb_gcam_org_pred=out_file_pre..im_num..'_gb_gcam_org_pred.jpg';
                    local out_file_gb_gcam_th_pred=out_file_pre..im_num..'_gb_gcam_th_pred.jpg';
                    local out_file_blur_pred = out_file_pre..im_num..'_blur_pred.jpg';

                    local gcam_pred=gcam_curr_pred[im_num]
                    local gb_gcam_pred = gb_gcam_all_pred[im_num];
                    local gb_gcam_org_pred = gb_gcam_org_all_pred[im_num]
                    -- local hm_pred = utils.to_heatmap(gcam_pred:float())
                    local gb_gcam_th_pred = gb_gcam_th_all_pred[im_num][1];
                    local im_blur_pred = im_blur_all_pred[im_num][1]
                    
                    image.save(out_file_gb_gcam_pred, image.toDisplayTensor(gb_gcam_pred))
                    image.save(out_file_gb_gcam_org_pred, image.toDisplayTensor(gb_gcam_org_pred))
                    -- image.save(out_file_hm_pred, image.toDisplayTensor(hm_pred))
                    image.save(out_file_gb_gcam_th_pred, image.toDisplayTensor(gb_gcam_th_pred))
                    image.save(out_file_blur_pred,image.toDisplayTensor(im_blur_pred));
                    
                end

            end
        end

    end


    function data:shuffleLines(lines)
        local x=lines;
        local len=#lines;

        local shuffle = torch.randperm(len)
        
        local lines2={};
        for idx=1,len do
            lines2[idx]=x[shuffle[idx]];
        end
        return lines2;
    end


    function data:shuffleLinesOptimizing(lines,im,labels)
        local x=lines;
        local len=#lines;

        local shuffle = torch.randperm(len)
        
        local im_2=im:clone();
        local labels_2=labels:clone();

        local lines2={};
        for idx=1,len do
            lines2[idx]=x[shuffle[idx]];
            im_2[idx]=im[shuffle[idx]];
            labels_2[idx]=labels[shuffle[idx]];
        end
        im=0;
        labels=0;
        lines=0;
        return lines2,im_2,labels_2;
    end



    function data:getTrainingData()
        
        local start_idx_face_before = self.start_idx_face
        
        self.training_set.data=torch.zeros(self.batch_size,3,self.crop_size[1],self.crop_size[2]);
        self.training_set.label=torch.zeros(self.batch_size);
        self.training_set.input={};
        
        self.start_idx_face=self:addTrainingData(self.training_set,self.batch_size,self.start_idx_face)    

        if self.start_idx_face<=start_idx_face_before and self.augmentation then
            print ('shuffling data'..self.start_idx_face..' '..start_idx_face_before )
            if not self.optimize then
                self.lines_face=self:shuffleLines(self.lines_face);
            else
                self.lines_face,self.training_images,self.training_labels=self:shuffleLinesOptimizing(self.lines_face,self.training_images,self.training_labels);
            end
        end

    end

    
    function data:readDataFile(file_path)
        local file_lines = {};
        for line in io.lines(file_path) do 
            local start_idx, end_idx = string.find(line, ' ');
            local img_path=string.sub(line,1,start_idx-1);
            local img_label=string.sub(line,end_idx+1,#line);
            file_lines[#file_lines+1]={img_path,img_label};
        end 
        return file_lines

    end

    function data:augmentImage(img_face) 

        
        local rand=math.random(2);
        if rand==1 then
            image.hflip(img_face,img_face);
        end
        
        assert (self.input_size[1]>=self.crop_size[1]);
        local x=math.random(self.input_size[1]-self.crop_size[1]+1);
        local y=math.random(self.input_size[2]-self.crop_size[2]+1);
        img_face=img_face[{{},{y,y+self.crop_size[2]-1},{x,x+self.crop_size[1]-1}}];

        local angle_deg = (math.random()*(self.angles[2]-self.angles[1]))+self.angles[1]
        local angle=math.rad(angle_deg)
        img_face=image.rotate(img_face,angle,"bilinear");
        
        local alpha = (math.random()*(self.scale[2]-self.scale[1]))+self.scale[1]
        local img_face_sc=image.scale(img_face,'*'..alpha);
        if alpha<1 then
            local pos=math.floor((img_face:size(2)-img_face_sc:size(2))/2)+1
            img_face=torch.zeros(img_face:size());
            img_face[{{},{pos,pos+img_face_sc:size(2)-1},{pos,pos+img_face_sc:size(2)-1}}]=img_face_sc;
        else
            local pos=math.floor((img_face_sc:size(2)-img_face:size(2))/2)+1
            img_face=torch.zeros(img_face:size());
            img_face=img_face_sc[{{},{pos,pos+img_face:size(2)-1},{pos,pos+img_face:size(2)-1}}];
        end
        
        local delta = math.floor(torch.abs(alpha-1)*self.input_size[1]);
        local x_translate=math.random(-delta,delta)
        local y_translate=math.random(-delta,delta)
        img_face = image.translate(img_face, x_translate, y_translate);
        img_face[img_face:ne(img_face)]=0;
        
        return img_face;
    end

    function data:processIm(img_face)
        
        img_face=img_face*255; 
        if img_face:size()[1]==1 then
            img_face= torch.cat(img_face,img_face,1):cat(img_face,1)
        end

        for i=1,img_face:size()[1] do
            img_face[i]:csub(self.mean[i])
        end

        if img_face:size(2)~=self.input_size[1] and self.augmentation then 
            img_face = image.scale(img_face,self.input_size[1],self.input_size[2]);
        elseif img_face:size(2)~=self.crop_size[1] and not self.augmentation then 
            img_face = image.scale(img_face,self.crop_size[1],self.crop_size[2]);
        end
    
        if self.augmentation then
            img_face = self:augmentImage(img_face);
        end

        if self.bgr then
            local img_face_temp=img_face:clone();
            img_face[{1,{},{}}]=img_face_temp[{3,{},{}}];
            img_face[{3,{},{}}]=img_face_temp[{1,{},{}}];
        end

        return img_face
    end

    function data:addTrainingData(training_set,batch_size,start_idx_face,curr_idx)
        local list_idx=start_idx_face;
        local list_size=#self.lines_face;
        -- local 
        if not curr_idx then
            curr_idx=1;
        end

        while curr_idx<= batch_size do
            local img_path_face,label_face,status_img_face,img_face;
            if self.optimize then
                status_img_face=true;
                img_path_face=self.lines_face[list_idx];
                label_face=self.training_labels[list_idx];
                img_face=self.training_images[list_idx]:clone();
            else
                img_path_face=self.lines_face[list_idx][1];
                label_face=self.lines_face[list_idx][2];
                status_img_face,img_face=pcall(image.load,img_path_face);
            end
            
            if status_img_face then
                img_face=self:processIm(img_face)
                training_set.data[curr_idx]=img_face;

                if self.twoClass then
                    training_set.label[curr_idx]=tonumber(label_face);
                else
                    training_set.label[curr_idx]=tonumber(label_face)+1;
                end
                training_set.input[curr_idx]=img_path_face;
            else
                print ('PROBLEM READING INPUT');
                curr_idx=curr_idx-1;
            end
            list_idx=(list_idx%list_size)+1;
            curr_idx=curr_idx+1;
        end
        return list_idx;
    end

    
end

return data