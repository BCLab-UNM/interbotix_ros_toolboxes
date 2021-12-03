classdef InterbotixManipulatorXS < handle
% Standalone Module to control an Interbotix Arm and Gripper
    properties
        % dxl - Reference to the class's InterbotixRobotXSCore object
        dxl
        
        % arm - Reference to the class's InterbotixArmXSInterface object
        arm
        
        % gripper - Reference to the class's InterbotixGripperXSInterface object
        gripper
        
        % group_name - Joint group name that contains the 'arm' joints as 
        % defined in the 'motor_config' yaml file; typically, this is 'arm'
        group_name
        
        % gripper_name - Name of the gripper joint as defined in the 
        % 'motor_config' yaml file; typically, this is 'gripper'
        gripper_name
    end
    
    methods
        function obj = InterbotixManipulatorXS(robot_model, group_name, gripper_name, robot_name, opts)
        % Constructor for the InterbotixManipulatorXS object
            arguments
                
                % robot_model - Interbotix Arm model (ex. 'wx200' or 'vx300s')
                robot_model string = ""
                
                % group_name - joint group name that contains the 'arm' joints 
                % as defined in the 'motor_config' yaml file; typically, this 
                % is 'arm'
                group_name string = "arm"
                
                % gripper_name - name of the gripper joint as defined in the 
                % 'motor_config' yaml file; typically, this is 'gripper'
                gripper_name string = "gripper"
                
                % robot_name - defaults to value given to 'robot_model'; this 
                % can be customized if controlling two of the same arms from 
                % one computer (like 'arm1/wx200' and 'arm2/wx200')
                robot_name string = ""
                
                % moving_time - time [s] it should take for all joints in the 
                % arm to complete one move
                opts.moving_time double = 2.0
                
                % accel_time - time [s] it should take for all joints in the 
                % arm to accelerate/decelerate to/from max speed
                opts.accel_time double = 0.3
                
                % gripper_pressure - fraction from 0 - 1 where '0' means the 
                % gripper operates at 'gripper_pressure_lower_limit' and '1' 
                % means the gripper operates at 'gripper_pressure_upper_limit'
                opts.gripper_pressure double = 0.5
                
                % gripper_pressure_lower_limit - lowest 'effort' that should be 
                % applied to the gripper if gripper_pressure is set to 0; it 
                % should be high enough to open/close the gripper (~150 PWM 
                % or ~400 mA current)
                opts.gripper_pressure_lower_limit double = 150
                
                % gripper_pressure_upper_limit - largest 'effort' that should 
                % be applied to the gripper if gripper_pressure is set to 1; 
                % it should be low enough that the motor doesn't 'overload' 
                % when gripping an object for a few seconds (~350 PWM or ~900 mA)
                opts.gripper_pressure_upper_limit double = 350
                
                % init_node - set to True if the InterbotixRobotXSCore class 
                % should initialize the ROS node; set to False
                opts.init_node {mustBeNumericOrLogical} = 1
            end
            obj.group_name = group_name;
            obj.gripper_name = gripper_name;

            % create the core dxl object
            obj.dxl = InterbotixRobotXSCore( ...
                robot_model, robot_name, opts.init_node);
            
            % create the arm interface object
            obj.arm = InterbotixArmXSInterface( ...
                obj.dxl, robot_model, group_name, ...
                moving_time=opts.moving_time, accel_time=opts.accel_time);
            
            % create the gripper interface object
            if ~(gripper_name=="")
                obj.gripper = InterbotixGripperXSInterface( ...
                    obj.dxl, gripper_name, ...
                    gripper_pressure=opts.gripper_pressure, ...
                    gripper_pressure_lower_limit=opts.gripper_pressure_lower_limit, ...
                    gripper_pressure_upper_limit=opts.gripper_pressure_upper_limit);
            end
        end

        function success = stop_timers(obj)
        % stop_timers Stops all timers with the group_name or the gripper_name tag
        % 
        % returns success - indication of whether or not the timers were stopped
            success = true;
            try
                if ~isempty(obj.gripper)
                    group_timers = timerfind("Tag", obj.group_name);
                    gripper_timers = timerfind("Tag", obj.gripper_name);
                    if ~isempty(group_timers)
                        stop(group_timers)
                        fprintf("%s stopped successfully.\n", group_timers(:).Name)
                        delete(group_timers);
                        fprintf("All group timers deleted successfull.\n")
                    else
                        fprintf("No timers to delete in group.\n")
                    end
                    if ~isempty(gripper_timers)
                        stop(gripper_timers)
                        fprintf("%s stopped successfully.\n", gripper_timers(:).Name)
                        delete(gripper_timers);
                        fprintf("All gripper timers deleted successfully.\n")
                    else
                        fprintf("No timers to delete in gripper.\n")
                    end
                    fprintf("All timers in manipulator stopped and deleted.\n")
                else
                    fprintf("Manipulator has no timers to be stopped.\n")
                end
            catch ME
                success = false;
                fprintf("Something went wrong when stopping timers. Run `delete(timerfindall)` to stop and delete all timers instead.\n")
                rethrow(ME)
            end
        end

    end
end
