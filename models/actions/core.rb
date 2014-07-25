require 'models/profiles/main'



#include Main

class Main < Roby::Actions::Interface
    
    action_library
     PIPE_SPEED=0.5

     def name
         "Avalon's Action library"
     end


    describe("lawn_mover_over_pipe")
    state_machine "lawn_mover_over_pipe" do
        s1 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => -5, :y => 0)
        s2 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => -5, :y => 4)
        s3 = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5)
        s4 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 10, :x => 0, :y => 4)
        s5 = state simple_move_def(:finish_when_reached => true, :heading => -Math::PI/2.0, :depth => -4, :delta_timeout => 5)
        s6 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => 0, :y => 0)
        s7 = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5)
        s8 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 10, :x => 5, :y => 0)
        s9 = state simple_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 5)
        s10 =state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => 5, :y => 4)

        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s3)
        transition(s3.success_event,s4)
        transition(s4.success_event,s5)
        transition(s5.success_event,s6)
        transition(s6.success_event,s7)
        transition(s7.success_event,s8)
        transition(s8.success_event,s9)
        transition(s9.success_event,s10)
        forward s10.success_event,success_event
    end
    

    describe("intelligend follow-pipe, only emitting weak_signal if heading is correkt").
	optional_arg('turn_dir', 'the turn direction').
	required_arg('initial_heading', 'the heading for the pipe to follow').
        required_arg('precision', 'precision the heading need to be')
    action_script "intelligent_follow_pipe" do
        follow = task pipeline_def(:heading => initial_heading,         :speed_x => PIPE_SPEED, :turn_dir=> turn_dir, :timeout => 120)
        execute follow
        #wait follow.weak_signal_event
        wait follow.end_of_pipe_event
        emit success_event
#        Robot.info "EndOfPipeEvent empfangen"
#        yaw = [:pose, :orientation].inject(State) do |value, field_name|
#            if value.respond_to?(field_name)
#                value.send(field_name)
#            else break
#            end
#        end
#        
#        script do
#            if !yaw.nil? && (yaw.yaw < 10* 180/Math::PI) && (yaw.yaw > 10 * -180/Math::PI) #&& State.pose.orientation.yaw.read < precision * Math::PI && State.pose.orientation.yaw.read > -precision * MATH::PI
#                Robot.info "EndOfPipeEvent weitergeleitet"
#                emit success_event 
#            end
#            Robot.info "EndOfPipeEvent ignoriert"
#        end
    end
    
    describe("follow-pipe-a-turn-at-e-of-pipe").
	optional_arg('turn_dir', 'the turn direction').
	required_arg('initial_heading', 'the heading for the pipe to follow').
	required_arg('post_heading', 'the heading for the pipe to follow')
    state_machine "follow_pipe_a_turn_at_e_of_pipe" do
       #follow = state pipeline_def(:heading => initial_heading, 	:speed_x => PIPE_SPEED, :turn_dir=> turn_dir)
        follow = state intelligent_follow_pipe(initial_heading: initial_heading, precision: 0.5, turn_dir: turn_dir)
       stop = state pipeline_def(:heading => initial_heading, 	:speed_x => -PIPE_SPEED/2.0, :turn_dir=> turn_dir, :timeout => 10)
       turn= state pipeline_def(:heading => post_heading, 	:speed_x => 0, 		 :turn_dir=> turn_dir, :timeout => 10)
       start(follow)
       transition(follow, follow.success_event,stop)
       transition(stop.success_event,turn)
       forward turn.follow_pipe_event, success_event
       forward turn.success_event, success_event
    end

    
   

    describe("Ping and Pong (once) on an pipeline").
	optional_arg('post_heading', 'The final heading of the AUV, after pipeline tracking',3.13)
    state_machine "pipe_ping_pong" do
        pipeline = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 0,:post_heading => 3.13, :turn_dir => 1)
        pipeline2 = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 3.13, :post_heading => post_heading, :turn_dir => 1)
        start(pipeline)
        transition(pipeline.success_event,pipeline2)
        forward pipeline2.success_event, success_event
    end
    
    describe("Ping and Pong inf on an pipeline")
    state_machine "loop_pipe_ping_pong" do
        s1 = state pipe_ping_pong(:post_heading => 0)
        s2 = state pipe_ping_pong(:post_heading => 0)
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s1)
    end

    
    
    describe("simple_move_tests")
    state_machine "simple" do
        s1 = state simple_move_def(:heading=>0, :depth=>-5,:timeout =>15)
        s2 = state simple_move_def(:heading=>0, :speed_x=>3 ,:depth=>-5, :timeout=> 15)
        s3 = state simple_move_def(:heading => Math::PI*0.5, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s4 = state simple_move_def(:heading => Math::PI*1.0, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s5 = state simple_move_def(:heading => Math::PI*1.5, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s6 = state simple_move_def(:heading => 0, :speed_x => 0 ,:depth=>-5, :timeout=> 15)
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s3)
        transition(s3.success_event,s4)
        transition(s4.success_event,s5)
        transition(s5.success_event,s6)
        forward s6.success_event, success_event
    end


    describe("dive_and_localize")
    state_machine "dive_and_localize" do
        control = state simple_move_def(:heading => 0, :depth => -5, :timeout => 15) 
        localization = state localization_def 
        control.depends_on localization, :role => "detector"
        start(control)
        forward control.success_event, success_event
    end

#    describe("drive_to_pipeline")
#    state_machine "drive_to_pipeline" do
#        
#        init = state dive_and_localize 
#        
#        control = state simple_move_def(:heading => 0, :depth => -5, :timeout => 60) 
#        localization = state localization_detector_def 
#        localization.depends_on control, :role => "detector"
#
#        bottom_left_corner =        state target_move_def(:finish_when_reached => true, :delta_timeout => 2  , :heading =>  Math::PI*0.5, :depth => -5, :x => -5, :y => -5)
#        top_left_corner =           state target_move_def(:finish_when_reached => true, :delta_timeout => 2  , :heading =>  Math::PI*0.5, :depth => -5, :x => -5, :y =>  5)
#        top_right_corner =          state target_move_def(:finish_when_reached => true, :delta_timeout => 2  , :heading =>  Math::PI*0.5, :depth => -5, :x =>  5, :y =>  5)
#        pipeline_check_position =   state target_move_def(:finish_when_reached => true,  :delta_timeout => 60, :heading => -Math::PI,     :depth => -6, :x =>  5, :y =>  7.5)
#
#        #First diving, to keep the localization a chance to get a valid position reading 
#        start(init)
#
#        forward localization.success_event, failed_event
#        transition(init.success_event, localization)
#        transition(localization.position1_event, pipeline_check_position)
#        transition(localization.position2_event, pipeline_check_position) 
#        transition(localization.position3_event, pipeline_check_position)
#        transition(localization.position4_event, top_left_corner)
#        transition(localization.position5_event, top_left_corner)
#        transition(localization.position6_event, top_right_corner)
#        transition(localization.position7_event, top_left_corner)
#        transition(localization.position8_event, bottom_left_corner)
#        transition(localization.position9_event, bottom_left_corner)
#        transition(bottom_left_corner.success_event, top_left_corner)
#        transition(top_left_corner.success_event, pipeline_check_position)
#        transition(top_right_corner.success_event, pipeline_check_position)
#        forward pipeline_check_position.success_event, success_event #TODO better failed?, because this should never be reached the composition should be stopped before
#    end
    
    describe("to_window")
    state_machine "to_window" do
        s1 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -5.5, :delta_timeout => 10, :x => 7, :y => 6.5)
        s2 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -5.5, :delta_timeout => 120, :x => 8, :y => 6.5)
        start(s1)

        transition s1.success_event, s2 
        forward s2.success_event, success_event
    end
    
   
    describe("Find_pipe_with_localization").
        optional_arg("check_pipe_angle",false)
    action_state_machine "find_pipe_with_localization" do
        find_pipe_back = state target_move_def(:finish_when_reached => false , :heading => 1, :depth => -6, :x => -6.5, :y => --0.5, :timeout => 180) 
        pipe_detector = state pipeline_detector_def
        pipe_detector.depends_on find_pipe_back, :role => "detector"
        start(pipe_detector)

#        pipe_detector.monitor(
#            'angle_checker', #the Name
#            pipe_detector.find_port('pipeline'), #the port for the reader
#            :check_pipe_angle => check_pipe_angle). #arguments
#            trigger_on do |pipeline|
#                angle_in_range = true
#                if check_pipe_angle
#                    angle_in_range = pipeline.angle < 0.1 && pipeline.angle > -0.1
#                end
#                state_valid = pipeline.inspection_state == :ALIGN_AUV || pipeline.inspection_state == :FOLLOW_PIPE
#                state_valid && angle_in_range #last condition
#            end. emit pipe_detector.success_event
        forward pipe_detector.align_auv_event, success_event
        forward pipe_detector.follow_pipe_event, success_event

        forward pipe_detector.success_event, success_event
        forward pipe_detector,find_pipe_back.success_event,failed_event #timeout here on moving
    end

end
