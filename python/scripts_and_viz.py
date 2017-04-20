import numpy as np;
import cv2;
import util;
import os;
import visualize;
import scipy;
import math;
dir_server='/home/SSD3/maheen-data/';
click_str='http://vision1.idav.ucdavis.edu:1000/';


def writeBlurScript(\
    path_to_th,
    out_dir_meta,
    dir_files,
    fold_num,
    batchSize=128,
    learningRate=0.01,
    ratioBlur=0,
    incrementDifficultyAfter=0,
    iterations=1000,
    saveAfter=100,
    testAfter=10,
    dispAfter=1,
    dispPlotAfter=10,
    batchSizeTest=128,
    modelTest=None,
    resume_dir_meta=None
    ):
    data_path=os.path.join(dir_files,'train_'+str(fold_num)+'.txt');
    val_data_path=os.path.join(dir_files,'test_'+str(fold_num)+'.txt');
    mean_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_mean.png');
    std_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_std.png');

    epoch_size=len(util.readLinesFromFile(data_path))/batchSize;
    totalSizeTest=len(util.readLinesFromFile(val_data_path));
    # print str(batchSizeTest)+',',
    iterationsTest=int(math.ceil(totalSizeTest/float(batchSizeTest)));
    outDir=os.path.join(out_dir_meta,str(fold_num));

    command=['th',path_to_th];
    if resume_dir_meta is not None:
        model_path_resume=os.path.join(resume_dir_meta,str(fold_num),'final','model_all_final.dat');
        command = command+['-model',model_path_resume];            

    command = command+['-mean_im_path',mean_im_path];
    command = command+['-std_im_path',std_im_path];
    command = command+['-batchSize',batchSize];
    
    command = command+['learningRate',learningRate];

    command = command+['-ratioBlur',ratioBlur];
    command = command+['-incrementDifficultyAfter',0];
        

    command = command+['-iterations',1000*epoch_size];
    command = command+['-saveAfter',100*epoch_size];
    command = command+['-testAfter',10*epoch_size];
    command = command+['-dispAfter',1*epoch_size];
    command = command+['-dispPlotAfter',10*epoch_size];

    command = command+['-val_data_path',val_data_path];
    command = command+['-data_path',data_path];
    
    command = command+['-iterationsTest',iterationsTest];
    command = command+['-batchSizeTest',batchSizeTest]
    
    command = command+['-outDir',outDir];
    if modelTest is None:
        command = command+['-modelTest',os.path.join(outDir,'final','model_all_final.dat')];
    else:
        command = command+['-modelTest',modelTest];
    command = [str(c_curr) for c_curr in command];
    command=' '.join(command);
    return command;

def writeCKScripts():
    experiment_name='khorrami_ck_rerun';
    out_dir_meta='../experiments/'+experiment_name;
    util.mkdir(out_dir_meta);
    out_script='../scripts/train_'+experiment_name+'.sh';
    # path_to_th='train_khorrami_basic.th';
    path_to_th='train_khorrami_withBlur.th';

    dir_files='../data/ck_96/train_test_files';
    # resume_dir_meta='../experiments/khorrami_basic_aug_fix_resume'
    num_folds=10;

    resume_dir_meta=None
    noBias=False;
    learningRate = 0.01;
    batchSizeTest=128;
    batchSize=128;
    ratioBlur=0.0;

    # experiment_name='khorrami_basic_tfd_withBias';
    # out_dir_meta='../experiments/'+experiment_name;
    # util.mkdir(out_dir_meta);
    # out_script='../scripts/train_'+experiment_name+'.sh';
    # path_to_th='train_khorrami_basic.th';

    # dir_files='../data/tfd/train_test_files';
    # resume_dir_meta=None
    # # '../experiments/khorrami_basic_tfd_resume'
    # noBias=False;
    # num_folds=5;

    # learningRate = 0.01;
    # batchSizeTest=128;
    # batchSize=128;

    commands=[];
    # print '{',
    for fold_num in range(num_folds):
        
        data_path=os.path.join(dir_files,'train_'+str(fold_num)+'.txt');
        val_data_path=os.path.join(dir_files,'test_'+str(fold_num)+'.txt');
        mean_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_mean.png');
        std_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_std.png');

        epoch_size=len(util.readLinesFromFile(data_path))/batchSize;
        totalSizeTest=len(util.readLinesFromFile(val_data_path));
        # print str(batchSizeTest)+',',
        iterationsTest=int(math.ceil(totalSizeTest/float(batchSizeTest)));
        outDir=os.path.join(out_dir_meta,str(fold_num));

        command=['th',path_to_th];
        if resume_dir_meta is not None:
            model_path_resume=os.path.join(resume_dir_meta,str(fold_num),'final','model_all_final.dat');
            command = command+['-model',model_path_resume];            

        command = command+['-mean_im_path',mean_im_path];
        command = command+['-std_im_path',std_im_path];
        command = command+['-batchSize',batchSize];
        
        command = command+['learningRate',learningRate];
        if noBias:
            command = command+['-noBias'];

        command = command+['-ratioBlur',ratioBlur];
        command = command+['-incrementDifficultyAfter',0];
            

        command = command+['-iterations',1000*epoch_size];
        command = command+['-saveAfter',100*epoch_size];
        command = command+['-testAfter',10*epoch_size];
        command = command+['-dispAfter',1*epoch_size];
        command = command+['-dispPlotAfter',10*epoch_size];

        command = command+['-val_data_path',val_data_path];
        command = command+['-data_path',data_path];
        
        command = command+['-iterationsTest',iterationsTest];
        command = command+['-batchSizeTest',batchSizeTest]
        
        command = command+['-outDir',outDir];
        command = command+['-modelTest',os.path.join(outDir,'final','model_all_final.dat')];
        command = [str(c_curr) for c_curr in command];
        command=' '.join(command);
        print command;
        commands.append(command);
    # print '}';
    print out_script
    util.writeFile(out_script,commands);


def writeTFDSchemeScripts():
    
    # experiment_name='khorrami_basic_tfd_schemes_fullBlur';
    experiment_name='noBlur_meanFirst_pixel_augment';
    out_dir_meta='../experiments/'+experiment_name;
    util.mkdir(out_dir_meta);
    out_script='../scripts/train_'+experiment_name;
    # +'.sh';
    path_to_th='train_khorrami_withBlur.th';

    dir_files='../data/tfd/train_test_files';
    resume_dir_meta=None
    # '../experiments/khorrami_basic_tfd_resume'
    num_folds=5;

    learningRate = 0.01;
    batchSizeTest=128;
    batchSize=128;
    ratioBlur=0.0;
    schemes=['mix','mixcl'];
    # incrementDifficultyAfter=10*epoch_size;
    incrementDifficultyAfter=0;
    schemes=['noBlur_meanFirst_7out'];
    # model='../models/base_khorrami_model_7.dat';
    num_scripts=1;
    # print '{',
    commands=[];
    for fold_num in range(num_folds):
        for scheme in schemes:
            out_dir_meta_curr=os.path.join(out_dir_meta,scheme);
            util.mkdir(out_dir_meta_curr)
            data_path=os.path.join(dir_files,'train_'+str(fold_num)+'.txt');
            val_data_path=os.path.join(dir_files,'test_'+str(fold_num)+'.txt');
            mean_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_mean.png');
            std_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_std.png');

            
            epoch_size=len(util.readLinesFromFile(data_path))/batchSize;
            totalSizeTest=len(util.readLinesFromFile(val_data_path));
            # print str(batchSizeTest)+',',
            
            iterationsTest=int(math.ceil(totalSizeTest/float(batchSizeTest)));
            outDir=os.path.join(out_dir_meta_curr,str(fold_num));

            
            command=['th',path_to_th];
            if resume_dir_meta is not None:
                model_path_resume=os.path.join(resume_dir_meta,str(fold_num),'final','model_all_final.dat');
                command = command+['-model',model_path_resume];            
            else:
                command = command+['-model',model];            

            command = command+['-mean_im_path',mean_im_path];
            command = command+['-std_im_path',std_im_path];
            command = command+['-batchSize',batchSize];

            command = command+['-ratioBlur',ratioBlur];
            command = command+['-incrementDifficultyAfter',0];
            # 1*epoch_size];
            command = command+['-scheme',scheme];
            
            command = command+['learningRate',learningRate];

            command = command+['-iterations',1200*epoch_size];
            command = command+['-saveAfter',100*epoch_size];
            command = command+['-testAfter',10*epoch_size];
            command = command+['-dispAfter',1*epoch_size];
            command = command+['-dispPlotAfter',10*epoch_size];

            command = command+['-val_data_path',val_data_path];
            command = command+['-data_path',data_path];
            
            command = command+['-iterationsTest',iterationsTest];
            command = command+['-batchSizeTest',batchSizeTest]


            
            command = command+['-outDir',outDir];
            command = command+['-modelTest',os.path.join(outDir,'final','model_all_final.dat')];
            command = [str(c_curr) for c_curr in command];
            command=' '.join(command);
            # print command;
            commands.append(command);
        # print '}';
    print out_script

    commands=np.array(commands);
    commands_split=np.array_split(commands,num_scripts);
    for idx_commands,commands in enumerate(commands_split):
        out_file_script_curr=out_script+'_'+str(idx_commands)+'.sh';
        print idx_commands
        print out_file_script_curr
        # print commands;
        util.writeFile(out_file_script_curr,commands);


    # util.writeFile(out_script,commands);


def makeHTML_withPosts(out_file_html,im_dirs,num_ims_all,im_posts,gt_labels_all,pred_labels_all,num_batches_all=[1]):
    im_list=[];
    caption_list=[];

    for im_dir,num_ims,gt_labels,pred_labels,num_batches in zip(im_dirs,num_ims_all,gt_labels_all,pred_labels_all,num_batches_all):
        idx_curr=-1;
        
        for num_batch in num_batches:
            for num_im in num_ims:
                
                idx_curr=idx_curr+1;
                if idx_curr==len(gt_labels):
                    break;

                ims=[str(num_batch)+'_'+str(num_im)+im_post_curr for im_post_curr in im_posts]
                im_list_curr=[util.getRelPath(os.path.join(im_dir,im_curr),dir_server) for im_curr in ims];    
                gt=gt_labels[idx_curr];
                pred=pred_labels[idx_curr];
                caption_curr='right' if gt==pred else 'wrong';
                caption_curr=caption_curr+' '+str(gt)+' '+str(pred);
                caption_list_curr=[caption_curr+' '+im_curr[:im_curr.rindex('.')].lstrip('_') for im_curr in im_posts];
                caption_list.append(caption_list_curr);
                im_list.append(im_list_curr);

    visualize.writeHTML(out_file_html,im_list,caption_list);

def script_vizTestGradCam():
    dir_meta_pre=os.path.join(dir_server,'expression_project');
    out_dir_meta=os.path.join(dir_meta_pre,'experiments/khorrami_ck_rerun');
    test_pre='../data/ck_96/train_test_files/test_';
    # expressions=['neutral', 'anger', 'contempt', 'disgust', 'fear', 'happy', 'sadness', 'surprise'];
    # expressions=['pred', 'gt']
    expressions=['']
    npy_file='1_pred_labels.npy';
    npy_file_gt='1_gt_labels.npy';

    # , 'contempt', 'disgust', 'fear', 'happy', 'sadness', 'surprise'];
    pres=['_gb_gcam_org_','_hm_'];
    pres=['_gb_gcam_th_','_gb_gcam_','_gaussian_','_blur_'];
    # pres=['_gb_gcam_th_','_gb_gcam_','_gaussian_','_blur_'];
    pres=['_org','_gb_gcam','_hm','_gb_gcam_org','_gb_gcam_th','_gaussian','_blur']
    pres=['_org','_gb_gcam','_hm','_gb_gcam_org']
    # ,'_gaussian','_blur']

    num_folds=2;
    im_posts=[pre+exp_curr+'.jpg' for pre in pres for exp_curr in expressions]; 
            # ['_gb_gcam_org_'+exp_curr+'.jpg' for exp_curr in expressions]+\
            # ['_hm_'+exp_curr+'.jpg' for exp_curr in expressions];
            # ['_gb_gcam_'+exp_curr+'.jpg' for exp_curr in expressions]+\
            
    out_file_html=os.path.join(out_dir_meta,'test_results.html');
    # out_file_html=os.path.join(out_dir_meta,'viz_all.html');
    im_dirs=[];
    num_ims_all=[];
    gt_labels_all=[];
    pred_labels_all=[];
    num_batches_all=[];
    for fold_num in range(1,num_folds):

        out_dir=os.path.join(out_dir_meta,str(fold_num));
        # out_dir=out_dir_meta;
        # out_file_html=out_dir+'.html';
        im_dir=os.path.join(out_dir,'test_images');
        # im_dir=os.path.join(out_dir,'test_buildBlurryBatch');
        # out_file_html=os.path.join(out_dir,os.path.split(out_dir)[1]+'.html');
        # fold_num=0
        # fold_num%10;

        pred_labels=np.load(os.path.join(im_dir,npy_file)).astype(int);
        gt_labels=np.load(os.path.join(im_dir,npy_file_gt)).astype(int);
        # gt_data=util.readLinesFromFile(test_pre+str(fold_num)+'.txt')
        # gt_labels=np.array([int(line_curr.split(' ')[1]) for line_curr in gt_data])+1;
        # pred_labels = gt_labels;


        num_ims=list(range(1,128+1));
        num_batches_all.append(range(1,int(math.ceil(len(gt_labels)/128.0))+1));
        im_dirs.append(im_dir)
        num_ims_all.append(num_ims);
        gt_labels_all.append(gt_labels);
        pred_labels_all.append(pred_labels);
        
    makeHTML_withPosts(out_file_html,im_dirs,num_ims_all,im_posts,gt_labels_all,pred_labels_all,num_batches_all);
    print out_file_html.replace(dir_server,click_str);

def script_vizCompareActivations():
    dir_meta_pre=os.path.join(dir_server,'expression_project','experiments');
    out_dir_metas=[os.path.join(dir_meta_pre,'khorrami_basic_tfd_schemes_halfBlur/ncl'),os.path.join(dir_meta_pre,'khorrami_basic_tfd_resume_again')];
    test_pre='../data/tfd/train_test_files/test_';
    
    pres=['_gb_gcam_org_','_hm_'];
    pres=['_gb_gcam_th_','_gb_gcam_','_gaussian_','_blur_'];
    # pres=['_gb_gcam_th_','_gb_gcam_','_gaussian_','_blur_'];
    pres=['_gb_gcam','_hm','_gb_gcam_org','_gb_gcam_th','_gaussian','_blur']

    im_posts=['_org.jpg']+[pre+'.jpg' for pre in pres];
    # [pre+exp_curr+'.jpg' for pre in pres for exp_curr in expressions]; 
    out_file_html=os.path.join(out_dir_metas[0],'comparison.html');
    
    num_batches=range(1,7+1);

    im_dirs=[];
    num_ims_all=[];
    gt_labels_all=[];
    pred_labels_all=[];
    
    fold_num=0;

    for out_dir_meta in out_dir_metas:
        out_dir=os.path.join(out_dir_meta,str(fold_num));
        # out_dir=out_dir_meta;
        # out_file_html=out_dir+'.html';
        # im_dir=os.path.join(out_dir,'images');
        im_dir=os.path.join(out_dir,'test_images');
        # out_file_html=os.path.join(out_dir,os.path.split(out_dir)[1]+'.html');
        
        # pred_labels=np.load(os.path.join(out_dir,npy_file)).astype(int);
        gt_data=util.readLinesFromFile(test_pre+str(fold_num)+'.txt')
        gt_labels=np.array([int(line_curr.split(' ')[1]) for line_curr in gt_data])+1;
        pred_labels = gt_labels;

        num_ims=list(range(1,128+1));
        im_dirs.append(im_dir)
        num_ims_all.append(num_ims);
        gt_labels_all.append(gt_labels);
        pred_labels_all.append(os.path.split(out_dir_meta)[1][:3]);
    

    im_list=[];
    caption_list=[];

    for num_batch in num_batches:
        for num_im in num_ims:
            for im_dir,gt_labels,type_scheme in zip(im_dirs,gt_labels_all,pred_labels_all):
                ims=[str(num_batch)+'_'+str(num_im)+im_post_curr for im_post_curr in im_posts]
                im_list_curr=[util.getRelPath(os.path.join(im_dir,im_curr),dir_server) for im_curr in ims];
                gt_idx=128*(num_batch-1)+(num_im-1);
                # print gt_idx;
                if gt_idx>=len(gt_labels):
                    break;
                    # print num_batch,num_im
                    # raw_input();
                gt=gt_labels[gt_idx];
                # pred=pred_labels[num_im-1];
                caption_curr=str(num_batch)+'_'+str(num_im)+' '+str(gt)+' '+type_scheme;
                # 'right' if gt==pred else 'wrong';
                # caption_curr=caption_curr+' '+str(gt)+' '+str(pred);
                caption_list_curr=[caption_curr+' '+im_curr[:im_curr.rindex('.')].lstrip('_') for im_curr in im_posts];
                caption_list.append(caption_list_curr);
                im_list.append(im_list_curr);

    visualize.writeHTML(out_file_html,im_list,caption_list);

    # makeHTML_withPosts(out_file_html,im_dirs,num_ims_all,im_posts,gt_labels_all,pred_labels_all);
    print out_file_html.replace(dir_server,click_str);

def writeCKScripts_viz_inc():
    experiment_name='ck_inc_viz';
    out_dir_meta='../experiments/'+experiment_name;
    util.mkdir(out_dir_meta);
    out_script='../scripts/test_'+experiment_name;
    # +'.sh';
    # path_to_th='train_khorrami_basic.th';
    path_to_th='train_khorrami_withBlur.th';

    dir_files='../data/ck_96/train_test_files';
    # resume_dir_meta='../experiments/khorrami_basic_aug_fix_resume'
    num_folds=10;

    resume_dir_meta=None
    noBias=False;
    learningRate = 0.01;
    batchSizeTest=128;
    batchSize=128;
    ratioBlur=0.0;

    out_dir_model='../experiments/khorrami_ck_rerun';
    
    # print '{',
    # out_script_curr=out_script+'_'+str(fold_num)+'.sh';
    commands=[];
    for fold_num in range(num_folds):
        for epoch_num in range(100,1100,100):
            out_dir_meta_curr=os.path.join(out_dir_meta,str(epoch_num));
            util.mkdir(out_dir_meta_curr);
            out_dir_model_curr=os.path.join(out_dir_model,str(fold_num));
            data_path=os.path.join(dir_files,'train_'+str(fold_num)+'.txt');
            epoch_size=len(util.readLinesFromFile(data_path))/batchSize;
            inc_num=epoch_size*epoch_num;
            modelTest=os.path.join(out_dir_model_curr,'intermediate','model_all_'+str(inc_num)+'.dat');
            assert os.path.exists(modelTest);
            command=writeBlurScript(path_to_th,out_dir_meta_curr,dir_files,fold_num,modelTest=modelTest);
            # print command;
            commands.append(command);
    
    print out_script+'.sh'
    print len(commands);
    util.writeFile(out_script+'.sh',commands);


def writeHTMLs_viz_inc():
    experiment_name='ck_inc_viz';
    out_dir_meta=os.path.join(dir_server,'expression_project','experiments/'+experiment_name);
    dir_files='../data/ck_96/train_test_files';
    num_folds=10;

    expressions=range(1,9);
    right=True;

    npy_file_pred='1_pred_labels.npy';
    npy_file_gt='1_gt_labels.npy';
    posts=['_org','_gb_gcam','_gb_gcam_pred','_hm','_hm_pred','_gb_gcam_org','_gb_gcam_org_pred']
    
    # num_folds=1;
    # im_posts=[pre+exp_curr+'.jpg' for pre in pres for exp_curr in expressions]; 
    

    epoch_range=list(range(100,1100,100));
        # ,1100,100));
    
    batchSizeTest=128;
    for expression_curr in expressions:
    
        out_file_html=os.path.join(out_dir_meta,str(expression_curr)+'.html');
        ims_all=[];
        captions_all=[];
        for fold_num in range(num_folds):    
            data_path=os.path.join(dir_files,'train_'+str(fold_num)+'.txt');
            gt_labels_file=os.path.join(out_dir_meta,str(epoch_range[0]),str(fold_num),'test_images',npy_file_gt);
            gt_labels=np.load(gt_labels_file);    
            num_batches=int(math.ceil(len(gt_labels)/128.0))
            im_pre=np.array([str(batch_num)+'_'+str(im_num) for batch_num in range(1,num_batches+1) for im_num in range(1,batchSizeTest+1)]);
            bin_keep=gt_labels==expression_curr;
            gt_rel=gt_labels[bin_keep]
            im_pre_rel=im_pre[bin_keep];

            dir_ims=[os.path.join(out_dir_meta,str(epoch_num),str(fold_num),'test_images') for epoch_num in epoch_range];
            pred_rels=[np.load(os.path.join(dir_curr,npy_file_pred))[bin_keep] for dir_curr in dir_ims];

            for idx_im_pre_curr,im_pre_curr in enumerate(im_pre_rel):
                for idx_epoch in range(len(dir_ims)):
                    im_row=[util.getRelPath(os.path.join(dir_ims[idx_epoch],im_pre_curr+post_curr+'.jpg'),dir_server) for post_curr in posts];
                    caption_pre='right' if pred_rels[idx_epoch][idx_im_pre_curr]==gt_rel[idx_im_pre_curr] else 'wrong'
                    caption_row=[str(idx_im_pre_curr)+' '+caption_pre+' '+str(epoch_range[idx_epoch])+' '+str(int(gt_rel[idx_im_pre_curr]))+' '+str(int(pred_rels[idx_epoch][idx_im_pre_curr]))]*len(im_row);
                    ims_all.append(im_row[:]);
                    captions_all.append(caption_row[:])

        visualize.writeHTML(out_file_html,ims_all,captions_all,100,100);
        print out_file_html.replace(dir_server,click_str);

                

def writeTestGradCamScript():
    num_folds=10;

    experiment_name='test_grad_cam';
    dir_files='../data/ck_96/train_test_files';
    out_dir_meta=os.path.join('../scratch',experiment_name);
    util.mkdir(out_dir_meta);
    out_script=os.path.join('../scripts',experiment_name+'.sh');
    path_to_th='grad_cam.th';
    dir_models='../experiments/khorrami_basic_aug_fix_resume_again';

    commands=[];
    for fold_num in range(num_folds):
        val_data_path=os.path.join(dir_files,'test_'+str(fold_num)+'.txt');
        mean_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_mean.png');
        std_im_path=os.path.join(dir_files,'train_'+str(fold_num)+'_std.png');
        batchSizeTest=len(util.readLinesFromFile(val_data_path));

        command=['th',path_to_th];
        command = command+['-model',os.path.join(dir_models,str(fold_num),'final','model_all_final.dat')];            

        command = command+['-mean_im_path',mean_im_path];
        command = command+['-std_im_path',std_im_path];
        
        command = command+['-val_data_path',val_data_path];
        
        command = command+['-iterationsTest',1];
        command = command+['-batchSizeTest',batchSizeTest];
        
        command = command+['-outDir',os.path.join(out_dir_meta,str(fold_num))];
        command = [str(c_curr) for c_curr in command];
        command=' '.join(command);
        print command;
        commands.append(command);

    util.writeFile(out_script,commands);




def main():
    writeHTMLs_viz_inc();
    # writeCKScripts_viz_inc();
    # script_vizTestGradCam()
    # writeCKScripts()
    # script_vizCompareActivations()
    # writeTFDSchemeScripts();
    # writeCKScripts();
    # writeTestGradCamScript()
    # script_vizTestGradCam();

if __name__=='__main__':
    main();