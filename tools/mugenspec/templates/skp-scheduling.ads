with SK;

--D @Interface
--D This package contains scheduling plans, minor frame synchronization barrier
--D configurations and subject to scheduling partition as well as scheduling
--D group ID mappings as specified by the system policy.
package Skp.Scheduling
is

   Max_Groups_Per_Partition : constant := __max_groups_per_partition__;

   type Scheduling_Partition_Range is range __scheduling_partition_range__;

   type Extended_Scheduling_Group_Range is
     range 0 .. __scheduling_group_count__;
   subtype Scheduling_Group_Range is Extended_Scheduling_Group_Range
     range 1 .. Extended_Scheduling_Group_Range'Last;

   No_Group : constant Extended_Scheduling_Group_Range
     := Extended_Scheduling_Group_Range'First;

   type Barrier_Index_Range is range 0 .. __max_barrier_count__;

   subtype Barrier_Range is
     Barrier_Index_Range range 1 .. Barrier_Index_Range'Last;

   No_Barrier : constant Barrier_Index_Range := Barrier_Index_Range'First;

   type Minor_Frame_Type is record
      Partition_ID : Scheduling_Partition_Range;
      Barrier      : Barrier_Index_Range;
      Deadline     : SK.Word64;
   end record;

   Null_Minor_Frame : constant Minor_Frame_Type := Minor_Frame_Type'
     (Partition_ID => Scheduling_Partition_Range'First,
      Barrier      => No_Barrier,
      Deadline     => 0);

   type Minor_Frame_Range is range __minor_range__;

   type Minor_Frame_Array is array (Minor_Frame_Range) of Minor_Frame_Type;

   type Major_Frame_Type is record
      Length       : Minor_Frame_Range;
      Minor_Frames : Minor_Frame_Array;
   end record;

   type Major_Frame_Range is range __major_range__;

   type Major_Frame_Array is array (Major_Frame_Range) of Major_Frame_Type;

   Null_Major_Frames : constant Major_Frame_Array := Major_Frame_Array'
     (others => Major_Frame_Type'
        (Length       => Minor_Frame_Range'First,
         Minor_Frames => Minor_Frame_Array'
           (others => Null_Minor_Frame)));

   type Scheduling_Plan_Type is array (CPU_Range) of Major_Frame_Array;

   Scheduling_Plans : constant Scheduling_Plan_Type := Scheduling_Plan_Type'(
__scheduling_plans__);

   subtype Barrier_Size_Type is
     Natural range 1 .. Natural (CPU_Range'Last) + 1;

   type Barrier_Config_Array is array (Barrier_Range) of Barrier_Size_Type;

   type Major_Frame_Info_Type is record
      Period         : SK.Word64;
      Barrier_Config : Barrier_Config_Array;
   end record;

   type Major_Frame_Info_Array is array (Major_Frame_Range)
     of Major_Frame_Info_Type;

   Major_Frames : constant Major_Frame_Info_Array := Major_Frame_Info_Array'(
__major_frames_info__);

   type Scheduling_Group_Index_Range is
      range 0 .. Max_Groups_Per_Partition - 1;
   type Scheduling_Group_Map is array (Scheduling_Group_Index_Range)
     of Extended_Scheduling_Group_Range;

   type Scheduling_Partition_Config_Type is record
      Last_Group_Index : Scheduling_Group_Index_Range;
      Groups           : Scheduling_Group_Map;
   end record
     with Dynamic_Predicate =>
       (for all I in Scheduling_Group_Index_Range =>
          (if I <= Last_Group_Index then
             Groups (I) /= No_Group
          else Groups (I) = No_Group));

   type Scheduling_Partition_Config_Array is array (Scheduling_Partition_Range)
     of Scheduling_Partition_Config_Type;

   Scheduling_Partition_Config : constant Scheduling_Partition_Config_Array
     := Scheduling_Partition_Config_Array'(
__scheduling_partitions__);

   type Scheduling_Group_Config_Type is record
      Initial_Subject : Global_Subject_ID_Type;
      Group_Index     : Scheduling_Group_Index_Range;
   end record;

   type Scheduling_Group_Config_Array is array (Scheduling_Group_Range)
     of Scheduling_Group_Config_Type;

   Scheduling_Group_Config : constant Scheduling_Group_Config_Array
     := Scheduling_Group_Config_Array'(
__scheduling_groups__);

   type Subject_To_Sched_Partition_Array is array (Global_Subject_ID_Type)
     of Scheduling_Partition_Range;

   Subject_To_Scheduling_Partition : constant Subject_To_Sched_Partition_Array
     := Subject_To_Sched_Partition_Array'(
__subj_to_scheduling_partition__);

   type Subject_To_Scheduling_Group_Array is array (Global_Subject_ID_Type)
     of Scheduling_Group_Range;

   Subject_To_Scheduling_Group : constant Subject_To_Scheduling_Group_Array
     := Subject_To_Scheduling_Group_Array'(
__subj_to_scheduling_group__);

   --  Returns the scheduling group ID of the subject specified by ID.
   function Get_Scheduling_Group_ID
     (Subject_ID : Global_Subject_ID_Type)
     return Scheduling_Group_Range
   is
     (Subject_To_Scheduling_Group (Subject_ID));

   --  Returns the scheduling partition ID of the subject specified by ID.
   function Get_Scheduling_Partition_ID
     (Subject_ID : Global_Subject_ID_Type)
     return Scheduling_Partition_Range
   is
     (Subject_To_Scheduling_Partition (Subject_ID));

   --  Returns the scheduling group ID of the group specified by index in the
   --  context of the given scheduling partition.
   function Get_Scheduling_Group_ID
     (Partition_ID : Scheduling_Partition_Range;
      Group_Index  : Scheduling_Group_Index_Range)
     return Scheduling_Group_Range
   is
     (Scheduling_Partition_Config (Partition_ID).Groups (Group_Index))
   with
      Pre => Group_Index <= Scheduling_Partition_Config
           (Partition_ID).Last_Group_Index;

   --  Returns the scheduling group index of the group specified by ID.
   function Get_Scheduling_Group_Index
     (Group_ID : Scheduling_Group_Range)
      return Scheduling_Group_Index_Range
   is
     (Scheduling_Group_Config (Group_ID).Group_Index);

end Skp.Scheduling;
