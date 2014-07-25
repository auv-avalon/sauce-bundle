require 'models/actions/core'

class Main




    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping_pong_pipe_wall_back_to_pipe" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 

        
        find_pipe_back = state find_pipe_with_localization 
        find_pipe_back = state find_pipe_with_localization
        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,find_pipe_back)

	#timeout occured
        forward find_pipe_back.failed_event, failed_event
        #we found back the pipeline
        forward find_pipe_back.success_event, success_event ##todo maybe use align_auv insted?

     end
    
    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping_pong_pipe_wall_back_to_pipe_with_window" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 
        window = state to_window

        find_pipe_back = state find_pipe_with_localization 
        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,window)
        transition(window.success_event,find_pipe_back)

	#timeout occured
        forward find_pipe_back.failed_event, failed_event
        #we found back the pipeline
        forward find_pipe_back.success_event, success_event ##todo maybe use align_auv insted?

     end

    describe("Do a pipeline ping-pong, pass two corners with wall servoing and goind back to pipe")
    state_machine "rocking" do
        s1 = state ping_pong_pipe_wall_back_to_pipe
        s2 = state ping_pong_pipe_wall_back_to_pipe
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s1)
    end

    describe("Do the minimal demo once")
    state_machine "minimal_demo_once" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5, :timeout => 15)
        
        s1 = state find_pipe_with_localization
        #pipeline1 = state intelligent_follow_pipe(:initial_heading => 0, :precision => 10, :turn_dir => 1)
        pipeline1 = state pipeline_def(:depth => -5.5, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 180)
        align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => 3.14, :depth => -5, :delta_timeout => 5, :timeout => 15)
        rescue_move = state target_move_def(:finish_when_reached => true, :heading => Math::PI, :depth => -5, :delta_timeout => 5, :x => 0.5, :y => 5.5)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 20) 
        
        surface = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => 1, :speed_x => 0.1, :delta_timeout => 5, :timeout => 30)

        start(init)
        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        transition(s1.failed_event, rescue_move)
        transition(pipeline1.end_of_pipe_event, align_to_wall)
        transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.lost_pipe_event, rescue_move)
        transition(rescue_move.success_event, wall1)
        transition(align_to_wall.success_event, wall1)
        
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, surface)
        forward surface.success_event, success_event
    end
    

    describe("Do the minimal demo for the halleneroeffnung, means pipeline, then do wall-following and back to pipe-origin")
    state_machine "minimal_demo" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -7, :delta_timeout => 5, :timeout => 15, :speed_x => 0)
        s1 = state find_pipe_with_localization(:check_pipe_angle => true) 
#        detector = state pipeline_detector_def
#        detector.depends_on s1
    
        #Follow pipeline to right end
        pipeline1 = state pipeline_def(:depth=> -7.1, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 120)
        #pipeline1 = state intelligent_follow_pipe(:precision => 5, :initial_heading => 0, :turn_dir=> 1)
        #pipeline1 = state intelligent_follow_pipe(:initial_heading => 0, :precision => 10, :turn_dir => 1)
        align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => 3.14, :depth => -6, :delta_timeout => 5, :timeout => 15)
        rescue_move = state target_move_def(:finish_when_reached => true, :heading => Math::PI, :depth => -6, :delta_timeout => 5, :x => 0.5, :y => 5.5, :speed_x => 0)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 30) 
        blind1 = state simple_move_def(:heading => 0.0, :depth => -6.0, :timeout => 5)
        blind2 = state simple_move_def(:heading => 0.0, :depth => -6.0, :timeout => 5, :speed_x => 0.15)

        start(init)
        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        transition(s1.failed_event, rescue_move)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.end_of_pipe_event, align_to_wall)
        transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.failed_event, rescue_move)
        #transition(pipeline1.lost_pipe_event, rescue_move)
        transition(rescue_move.success_event, wall1)
        transition(align_to_wall.success_event, wall1)
        
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, blind1)
        transition(blind1.success_event, blind2)
        transition(blind2.success_event, s1)
        
        #prepare_jumpin("wall" => wall1, "pipeline"=> pipeline1)
    end
    
    describe("Do the minimal demo for the halleneroeffnung, menas pipeline, then do wall-following and back to pipe-origin")
    state_machine "minimal_demo_blind" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5, :timeout => 15)
        #s1 = state find_pipe_with_localization_
    
        #Follow pipeline to right end
        
	pipeline1 = state trajectory_move_def(:target => 'over_pipeline', :timeout => 125)  
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 23) 

        start(init)
        transition(init.success_event, pipeline1)
#        transition(s1.success_event, pipeline1)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.reached_end_event, wall1)
        #transition(align_to_wall.success_event, wall1)
        
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, pipeline1)

    end
    
   
    #TODO This could be extended by adding additional mocups
    describe("do a full Demo, with visiting the window after wall-servoing")
    state_machine "full_demo" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -6, :delta_timeout => 5, :timeout => 15)
        s1 = state find_pipe_with_localization 
    
        #Follow pipeline to right end
        pipeline1 = state pipeline_def(:depth=> -5.5, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 180)
	align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => 3.14, :depth => -6, :delta_timeout => 5, :timeout => 15)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 20) 
        
		s2 = state find_pipe_with_localization 
    
        #Follow pipeline to right end
        pipeline1_2 = state pipeline_def(:depth=> -5.5, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 180)

        throught_becken = state trajectory_move_def(:target => "explore") 


        start(init)
        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.end_of_pipe_event, align_to_wall)
        transition(pipeline1.success_event, align_to_wall)
        transition(align_to_wall.success_event, wall1)
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, s2)
        transition(s2.success_event, pipeline1_2)
        transition(pipeline1_2.success_event, throught_becken)
        transition(pipeline1_2.end_of_pipe_event, throught_becken)
		transition(throught_becken.success_event,s1)
    end

    describe("Do the minimal demo for the halleneroeffnung, means pipeline, then do wall-following and back to pipe-origin")
    state_machine "advanced_demo" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -7, :delta_timeout => 5, :timeout => 15, :speed_x => 0)
        s1 = state find_pipe_with_localization 
#        detector = state pipeline_detector_def
#        detector.depends_on s1
    
        #Follow pipeline to right end
        pipeline1 = state pipeline_def(:depth=> -7, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 120)
        #pipeline1 = state intelligent_follow_pipe(:precision => 5, :initial_heading => 0, :turn_dir=> 1)
        #pipeline1 = state intelligent_follow_pipe(:initial_heading => 0, :precision => 10, :turn_dir => 1)
        align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => Math::PI/2, :depth => -7, :delta_timeout => 5, :timeout => 15)
        rescue_move = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -7, :delta_timeout => 5, :x => 0.5, :y => 5.5, :speed_x => 0)
        start_window_move = state target_move_def(:finish_when_reached => true, :heading => -Math::PI/5, :depth => -7, :delta_timeout => 5, :x => 9.5, :y => 0, :speed_x => 1)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 3) 
        #wall2 = state wall_right_def(:timeout => 30) 
        blind1 = state simple_move_def(:heading => Math::PI/3, :depth => -7.0, :timeout => 5)
        blind2 = state simple_move_def(:heading => Math::PI/3, :depth => -7.0, :timeout => 15, :speed_x => 0.15)

        start(init)
        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        transition(s1.failed_event, rescue_move)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.end_of_pipe_event, start_window_move)
        transition(pipeline1.success_event, start_window_move)
        transition(pipeline1.failed_event, rescue_move)
        #transition(pipeline1.lost_pipe_event, rescue_move)
        transition(start_window_move.success_event, align_to_wall)
        transition(align_to_wall.success_event, wall1)
        transition(rescue_move.success_event, start_window_move)
        
        transition(wall1.success_event, blind1)
        #transition(wall2.success_event, blind1)
        transition(blind1.success_event, blind2)
        transition(blind2.success_event, s1)
    end

    
    describe("Do the minimal demo for the halleneroeffnung, means pipeline, then do wall-following and back to pipe-origin")
    state_machine "advanced_demo_once" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -7, :delta_timeout => 5, :timeout => 15, :speed_x => 0)
        s1 = state find_pipe_with_localization 
#        detector = state pipeline_detector_def
#        detector.depends_on s1
    
        #Follow pipeline to right end
        pipeline1 = state pipeline_def(:depth=> -7.1, :heading => 0, :speed_x => 0.5, :turn_dir=> 1, :timeout => 120)
        #pipeline1 = state intelligent_follow_pipe(:precision => 5, :initial_heading => 0, :turn_dir=> 1)
        #pipeline1 = state intelligent_follow_pipe(:initial_heading => 0, :precision => 10, :turn_dir => 1)
        align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => 3.14, :depth => -6, :delta_timeout => 5, :timeout => 15)
        rescue_move = state target_move_def(:finish_when_reached => true, :heading => Math::PI, :depth => -6, :delta_timeout => 5, :x => 0.5, :y => 5.5, :speed_x => 0)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 30) 
        blind1 = state simple_move_def(:heading => 0.0, :depth => -6.0, :timeout => 5)
        blind2 = state simple_move_def(:heading => 0.0, :depth => -6.0, :timeout => 5, :speed_x => 0.15)

        start(init)
        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        transition(s1.failed_event, rescue_move)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.end_of_pipe_event, align_to_wall)
        transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.failed_event, rescue_move)
        #transition(pipeline1.lost_pipe_event, rescue_move)
        transition(rescue_move.success_event, wall1)
        transition(align_to_wall.success_event, wall1)
        
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, blind1)
        transition(blind1.success_event, blind2)
        forward blind2.success_event, success_event
    end


#    describe("Workaround1")
#    state_machine "wa1" do 
#        s1 = state drive_to_pipeline
#        detector = state pipeline_detector_def
#        detector.depends_on s1
#        start detector
#        forward detector.align_auv_event, success_event 
#    end

#    describe("Find pipeline localization based, and to a infinite pipe-ping-pong on it")
#    state_machine "start_pipe_loopings" do 
#        
#        detector = state trajectory_move_def(:target => "pipeline") 
#        #turn = state simple_move_def(:heading => -Math::PI, :timeout => 5) 
#
#        pipeline1 = state pipe_ping_pong(:post_heading => 0)
#        pipeline2 = state pipe_ping_pong(:post_heading => 0)
#        
#        start detector
#
#        transition(detector.success_event, pipeline1)
##        transition(turn.success_event, pipeline1)
#        transition(pipeline1.success_event, pipeline2)
#        transition(pipeline2.success_event, pipeline1)
#    end
    
end

#module FailureHandling
#    class Operator < Roby::Coordination::FaultResponseTable
#        describe("waits for the operator to do something").
#            returns(WaitForOperator)
#        def wait_for_operator
#            WaitForOperator.new
#        end
#        # This is a catch-all that makes the system stop doing anything until an
#        # operator comes
#        on_fault Roby::LocalizedError do
#            wait_for_operator!
#        end
#    end
#end
#
#module HBridgeFailure
#    class Retry
#        on_fault with_origin(HBrigde.timeout_event) do
##            retry
#        end
#
#
#    end
#end
