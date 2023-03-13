import os
import cv2
import shutil
import argparse
import numpy as np
import tkinter as tk
from glob import glob
from pathlib import Path
import matplotlib.pyplot as plt
from tkinter.filedialog import askdirectory
from matplotlib.widgets import Slider, Button


import sys
sys.path.append("../")

tk.Tk().withdraw() # part of the import if you are not using other tkinter functions

class LabelFixer():
    def __init__(self, all_paths:list, ignore_empty_folders=True):
        self.curr_path = all_paths[0]
        self.all_paths = all_paths
    
        self.data = np.array([0])
        self.kick_labels = None
        self.path_index = 0
        
        # TODO: Add functionality for this
        self.ignore_empty_folders = ignore_empty_folders
        
        self.modify_all = False
        #################### ABOUT KICKS ####################
        # Currently selected kick index
        self.current_stack = 0
        
        # Base kick labels (Nx2)
        self.kick_stacks = []
        
        # Stores the shifts for eack kick (Nx2)
        self.stack_configs = []
        
        # A variable to control the kick change by changing 
        self.changing_kick = False
        
        #---------------------- UI ----------------------#
        
        ########################### PLOTS ##########################
        self.fig, self.axes = plt.subplots(figsize=(15,7))
        self.fig.subplots_adjust(bottom=0.25, top=0.85)

        self.yagi1, = plt.plot([0, 0],label="Yagi_1", color=(0.3,0.5,0.1))
        self.yagi2, = plt.plot([0, 0],label="Yagi_2", color=(0.4,0.8,0.1))
        self.patch1, = plt.plot([0, 0],label="Patch_1", color=(0.5,0.3,0.1))
        self.patch2, = plt.plot([0, 0],label="Patch_2", color=(0.8,0.4,0.1))
        self.label, = plt.plot([0, 0])
        self.kick_highlight, = plt.plot([0,0], linewidth=3, color='#5fa7d4')


        ####################### BUTTONS ###########################
        # Axes for buttons        
        self.next_ax = self.fig.add_axes([0.8, 0.025, 0.1, 0.04]) # x,y,w,h
        self.prev_ax = self.fig.add_axes([0.7, 0.025, 0.1, 0.04]) 
        self.save_ax = self.fig.add_axes([0.8, 0.9, 0.1, 0.04])
        self.reset_ax = self.fig.add_axes([0.7, 0.9, 0.1, 0.04])
        self.delete_ax = self.fig.add_axes([0.7, 0.065, 0.1, 0.04])
        
        self.change_all_ax = self.fig.add_axes([0.8, 0.065, 0.1, 0.04]) # x,y,w,h
        # self.btn_ignore_empty_folders = self.fig.add_axes([0.13, 0.9, 0.05, 0.04]) # x,y,w,h
        
        # Button instances
        self.btn_next = Button(self.next_ax, 'Next (D)', color='#1f77b4', hovercolor='#2f87c4')
        self.btn_prev = Button(self.prev_ax, 'Previous (A)', color='#1f77b4', hovercolor='#2f87c4')
        self.btn_save = Button(self.save_ax, 'Save (Enter)', color=(0.1,0.8,0.5), hovercolor=(0.2,0.85,0.6))
        self.btn_reset = Button(self.reset_ax, 'Reset (R)', color='#fad874', hovercolor='#ffe884')
        self.btn_delete = Button(self.delete_ax, 'Delete Kick (Del)', color='#fa8074', hovercolor='#ff9884')
        self.btn_change_mode = Button(self.change_all_ax, 'Modify All (Ctrl+A)', color='#fad874', hovercolor='#fff894')
        # self.btn_ignore_empty_folders = Button(self.btn_ignore_empty_folders, 'Empty (Q)', color='#fad874', hovercolor='#fff894')
        # Button event listeners
        self.btn_next.on_clicked(self.load_next)
        self.btn_prev.on_clicked(self.load_prev)
        self.btn_save.on_clicked(self.save_ref)
        self.btn_reset.on_clicked(self.reset_ref)
        self.btn_delete.on_clicked(self.delete_kick)
        self.btn_change_mode.on_clicked(self.change_mode)
        # self.btn_ignore_empty_folders.on_clicked(self.include_empty_folders)
        
        ############################################################
        
        ####################### SLIDERS ###########################
        # Axes for sliders
        self.kick_ax = self.fig.add_axes([0.13, 0.15, 0.3, 0.05]) # x,y,w,h
        self.left_ax = self.fig.add_axes([0.13, 0.1, 0.3, 0.05])
        self.right_ax = self.fig.add_axes([0.13, 0.05, 0.3, 0.05])
        
        # Slider Instances
        self.kick_slider = Slider(ax=self.kick_ax, label='Kick (Z | X)', valmin=0, valmax=100, valinit=0, valstep=1)
        self.left_slider = Slider(ax=self.left_ax, label='Left shift (n | m)', valmin=-30, valmax=30, valinit=0, valstep=1)
        self.right_slider = Slider(ax=self.right_ax, label='Right shift(, | .)', valmin=-30, valmax=30, valinit=0, valstep=1)

        # Slider event listeners
        self.kick_slider.on_changed(self.change_kick)
        self.left_slider.on_changed(self.change_slider)
        self.right_slider.on_changed(self.change_slider)
        ############################################################
        
        self.axes.legend(loc='upper right')
        
        # Starting key event listener
        self.fig.canvas.mpl_connect('key_press_event', self.on_key_press)
        self.get_data()
        self.update()
        
        plt.show()
        
    
    def on_key_press(self,event):
        '''
        Run functions according to the pressed keys
        '''
        print(event.key)
        if event.key=='a':
            self.load_prev(event)
        elif event.key=='d':
            self.load_next(event)
        elif event.key=='enter':
            self.save_ref(event)
         
        elif event.key=='z' and not self.modify_all:
            if self.current_stack==0:
                self.current_stack = len(self.kick_stacks)-1
            self.current_stack-=1
            self.kick_slider.set_val(self.current_stack)
        elif event.key=='x' and not self.modify_all:
                if not self.modify_all:
                    if self.current_stack == len(self.kick_stacks)-1:
                        self.current_stack = 0
                    self.current_stack+=1
                self.kick_slider.set_val(self.current_stack)
        elif event.key=='ctrl+a':
            self.change_mode(event)
        elif event.key=='r':
            self.reset_ref(event)
        elif event.key=='delete':
            self.delete_kick(event)
        elif event.key=='n':
            self.left_slider.set_val(np.clip(self.left_slider.val-1,self.left_slider.valmin,self.left_slider.valmax))
        elif event.key=='m':
            self.left_slider.set_val(np.clip(self.left_slider.val+1,self.left_slider.valmin,self.left_slider.valmax))
        elif event.key==',':    
            self.right_slider.set_val(np.clip(self.right_slider.val-1,self.right_slider.valmin,self.right_slider.valmax))
        elif event.key=='.':    
            self.right_slider.set_val(np.clip(self.right_slider.val+1,self.right_slider.valmin,self.right_slider.valmax))
        elif event.key=="ctrl+0":
            self.fix_limits()
    def shift_kick_labels(self):
        '''
        Shift the kick labels according to the slider values (left, right) 
        '''
        res = np.zeros_like(self.data)
        # TODO: possible without for loop
        for index, kick in enumerate(self.kick_stacks):
            start = np.clip(kick[0] + self.stack_configs[index][0], 0, self.data.shape[0])
            end = np.clip(kick[1] + self.stack_configs[index][1], 0, self.data.shape[0])
            
            res[start:end]=1 
        return res
    
    def get_stacks(self):
        diff = np.diff(self.data, prepend=0, append=0)
        starts = np.where(diff==1)[0]
        ends = np.where(diff==-1)[0]

        return np.stack((starts, ends)).T
    
    def change_slider(self, slider):
        if not self.changing_kick:
            self.update()
            
    def change_kick(self, event):
        self.current_stack = self.kick_slider.val
        self.changing_kick = True
        self.left_slider.set_val(self.stack_configs[self.current_stack][0])
        self.right_slider.set_val(self.stack_configs[self.current_stack][1])
        self.changing_kick = False
        
        self.update()
        
    def next_prev(self, direction):
        self.left_slider.reset()
        self.right_slider.reset()
        self.kick_slider.reset()
        num_folders_whiled = 0
        while True:
            if self.path_index == len(self.all_paths)-1 and direction==1:
                self.path_index = 0
            elif self.path_index == 0 and direction==-1:
                self.path_index = len(self.all_paths)-1  
                
            self.path_index += direction
            
            self.curr_path = Path(self.all_paths[self.path_index])
            
            if os.path.exists(self.curr_path / "ref_kicks.npy"):
                self.data = np.load(self.curr_path / "ref_kicks.npy")
                if self.ignore_empty_folders:
                    if self.data.sum() != 0:
                        self.get_data()                               
                        break
                else:
                    self.get_data()                               
                    break
                
            if self.path_index > len(self.all_paths):
                break
                
            num_folders_whiled += 1
            
            if num_folders_whiled > len(self.all_paths):
                break
    

            
        self.update()
        
    def load_next(self, event):
        self.next_prev(1)
        
    def load_prev(self, event):
        self.next_prev(-1)
    
    def delete_kick(self, event):
        if self.current_stack is None or self.modify_all:
            return

        self.changing_kick = True
        self.left_slider.set_val(0)
        self.right_slider.set_val(0)
        self.changing_kick = False
        self.kick_stacks[self.current_stack][1] = self.kick_stacks[self.current_stack][0]
        self.update()
        
    def save_ref(self, event):
        np.save(self.curr_path / "ref_kicks.npy", self.kick_labels)
        print('saved')
        
    def reset_ref(self, event):
        shutil.copy(self.curr_path / "ref_kicks_orig.npy", self.curr_path / "ref_kicks.npy")
        self.get_data()
        
        self.changing_kick = True
        self.left_slider.set_val(0)
        self.right_slider.set_val(0)
        self.changing_kick = False
        
        self.update()
      
    def change_mode(self, event):
        if self.modify_all:
            self.btn_change_mode.__setattr__('color',"#fad874")
            self.modify_all = False
            self.kick_slider.active = True
            
            
            self.update()
        else:
            self.btn_change_mode.__setattr__('color',"#fff894")
            self.modify_all = True
            self.kick_slider.active = False
            
            self.update()

    def include_empty_folders(self, event):
        if self.ignore_empty_folders:
            self.btn_ignore_empty_folders.__setattr__('color',"#fad874")
            self.btn_ignore_empty_folders.__setattr__('label',"O Ignore Empty (Q)")
            
            self.ignore_empty_folders = False
            
            self.update()
        else:
            self.btn_ignore_empty_folders.__setattr__('color',"#fff894")
            self.btn_ignore_empty_folders.__setattr__('label',"o Ignore Empty (Q)")
            
            self.ignore_empty_folders = True
            
            self.update()
    
    def fix_limits(self):
        # Compute the up-shift value to shift the patch graph upper. (80% of the max value of yagi)
        self.upshift = self.amps[:,0].max()*0.8
        
        # Compute the y-limit of the plot
        self.ylim = self.amps.max()+self.upshift
        
        self.axes.set_xlim(0,self.amps.shape[0])
        self.axes.set_ylim(0,self.ylim+100)
             
    def get_data(self):
        print(f"Folder name: {self.curr_path}")
        if  not os.path.exists(self.curr_path / "ref_kicks.npy"):
            print("There is no ref_kicks.npy in the selected folder")
            self.data = np.zeros(0)
            return # Get out of the function
       
        self.data = np.load(self.curr_path / "ref_kicks.npy")
                
        # if self.data.sum()!=0:
        if not os.path.exists(self.curr_path / "ref_kicks_orig.npy"):
            shutil.copy(self.curr_path / "ref_kicks.npy", self.curr_path / "ref_kicks_orig.npy")

        self.kick_stacks = self.get_stacks()
        # self.stack_slider.max = len(self.kick_stacks)-1

        self.stack_configs = [np.array([0,0]) for i in range(len(self.kick_stacks))]

        target = np.load(self.curr_path / "RadarIfxMimose_00/target.npy")
        # self.amps, bins = decode(target)
        # print(target.shape)
        self.amps = target[:, :4].reshape([target.shape[0], 2, 2])
        #bins = target[:, 4:]

        self.fix_limits()
        
        self.kick_slider.ax.set_xlim(0,len(self.kick_stacks)-1)
        self.kick_slider.__setattr__('valmax',len(self.kick_stacks)-1)

    # The function to be called anytime a slider's value changes
    def update(self, print_save=False):
        # Set current folder name as title
        self.axes.set_title(f"{self.curr_path.parent.name}/{self.curr_path.name}")
        
        # Generate x values for of plot
        x_labels = np.arange(0,self.amps.shape[0])
        
        # Plot Yagi data
        self.yagi1.set_data(x_labels,self.amps[:,0,0])
        self.yagi2.set_data(x_labels,self.amps[:,0,1])
        
        #Plot Patch data
        self.patch1.set_data(x_labels,self.amps[:,1,0]+self.upshift)
        self.patch2.set_data(x_labels,self.amps[:,1,1]+self.upshift)

        # If modifiing all kicks
        if self.modify_all:
            for i in range(len(self.stack_configs)):
                self.stack_configs[i][0] = self.left_slider.val
                self.stack_configs[i][1] = self.right_slider.val
            self.kick_labels = self.shift_kick_labels()
            self.kick_highlight.set_data(0,0)
        # When a single kick is being modified
        else:
            self.stack_configs[self.current_stack][0] = self.left_slider.val
            self.stack_configs[self.current_stack][1] = self.right_slider.val
            self.kick_labels = self.shift_kick_labels()

            k_left = self.kick_stacks[self.current_stack][0] + self.stack_configs[self.current_stack][0]
            k_right = self.kick_stacks[self.current_stack][1] + self.stack_configs[self.current_stack][1]
            
            kick = self.kick_labels[k_left-1:k_right+1]
            kick_coord = np.arange(k_left-1, k_right+1)
            self.kick_highlight.set_data(kick_coord, kick*self.ylim-200)

        kick_lengths = []
        for i,kick in enumerate(self.kick_stacks):
            k_left = kick[0] + self.stack_configs[i][0]
            k_right = kick[1] + self.stack_configs[i][1]
            
            # TODO: Make the commented code to work with the 
            # k_center = (k_left + k_right) // 2 - 5
            # self.fig.axes[0].text(k_center, ylim-200, f"{i}", fontsize=10)
            # self.fig.axes[0].text(k_center, ylim-400, f"{k_right-k_left}", fontsize=10)
            
            kick_lengths.append(k_right-k_left)
        # print(kick_lengths)
        
        self.label.set_data(np.arange(0,self.kick_labels.shape[0]),self.kick_labels*self.ylim-200)
        self.fig.canvas.draw_idle()


if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root-folder", type=str, default=None, help="Root folder for the data", required=False)
    args = parser.parse_args()

    if args.root_folder is None:
        root_folder = Path(askdirectory())
        print("user chose", root_folder)

    all_paths = list(filter(lambda x: x if "background" not in x.as_posix() and "." not in x.as_posix() else None,list(root_folder.glob("*"))))

    if len(all_paths)==0:
        exit()

    LabelFixer(all_paths)


