--  Disable line length check
pragma Style_Checks ("-m");

package body Skp.Events
is

   type Trap_Table_Type is array (Trap_Range) of Event_Entry_Type;

   Null_Trap_Table : constant Trap_Table_Type := Trap_Table_Type'
     (others => Null_Event);

   type Event_Table_Type is array (Event_Range) of Event_Entry_Type;

   Null_Event_Table : constant Event_Table_Type := Event_Table_Type'
     (others => Null_Event);

   type Event_Action_Table_Type is array (Event_Range) of Event_Action_Type;

   Null_Event_Action_Table : constant Event_Action_Table_Type
     := Event_Action_Table_Type'(others => Null_Event_Action);

   type Subject_Events_Type is record
      Source_Traps  : Trap_Table_Type;
      Source_Events : Event_Table_Type;
      Target_Events : Event_Action_Table_Type;
   end record;

   type Subjects_Events_Array is array (Skp.Subject_Id_Type)
     of Subject_Events_Type;

   Subject_Events : constant Subjects_Events_Array := Subjects_Events_Array'(
      0 => Subject_Events_Type'(
       Source_Traps  => Trap_Table_Type'(
          00 => Event_Entry_Type'(
            Target_Subject => 2,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          48 => Event_Entry_Type'(
            Target_Subject => 2,
            Target_Event   => 1,
            Handover       => True,
            Send_IPI       => False),
          others => Null_Event),
       Source_Events => Event_Table_Type'(
          17 => Event_Entry_Type'(
            Target_Subject => 1,
            Target_Event   => 0,
            Handover       => False,
            Send_IPI       => True),
          18 => Event_Entry_Type'(
            Target_Subject => 2,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          others => Null_Event),
       Target_Events => Event_Action_Table_Type'(
          0 => Event_Action_Type'(
            Kind   => Inject_Interrupt,
            Vector => 32),
          others => Null_Event_Action)),
      1 => Subject_Events_Type'(
       Source_Traps  => Null_Trap_Table,
       Source_Events => Null_Event_Table,
       Target_Events => Event_Action_Table_Type'(
          0 => Event_Action_Type'(
            Kind   => Inject_Interrupt,
            Vector => 32),
          others => Null_Event_Action)),
      2 => Subject_Events_Type'(
       Source_Traps  => Trap_Table_Type'(
          00 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          02 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          03 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          04 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          05 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          06 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          08 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          09 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          10 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          11 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          12 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          13 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          14 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          15 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          16 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          17 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          18 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          19 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          20 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          21 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          22 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          23 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          24 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          25 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          26 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          27 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          28 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          29 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          30 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          31 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          32 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          33 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          34 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          36 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          37 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          39 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          40 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          41 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          43 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          44 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          45 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          46 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          47 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          48 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          49 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          50 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          51 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          53 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          54 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          55 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          56 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          57 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          58 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          59 => Event_Entry_Type'(
            Target_Subject => 0,
            Target_Event   => 0,
            Handover       => True,
            Send_IPI       => False),
          others => Null_Event),
       Source_Events => Event_Table_Type'(
          1 => Event_Entry_Type'(
            Target_Subject => 2,
            Target_Event   => 2,
            Handover       => False,
            Send_IPI       => False),
          others => Null_Event),
       Target_Events => Event_Action_Table_Type'(
          0 => Event_Action_Type'(
            Kind   => No_Action,
            Vector => Invalid_Vector),
          1 => Event_Action_Type'(
            Kind   => Inject_Interrupt,
            Vector => 12),
          2 => Event_Action_Type'(
            Kind   => Reset,
            Vector => Invalid_Vector),
          others => Null_Event_Action)),
      3 => Subject_Events_Type'(
       Source_Traps  => Null_Trap_Table,
       Source_Events => Null_Event_Table,
       Target_Events => Null_Event_Action_Table));

   -------------------------------------------------------------------------

   function Get_Source_Event
     (Subject_Id : Skp.Subject_Id_Type;
      Event_Nr   : Event_Range)
      return Event_Entry_Type
   is (Subject_Events (Subject_ID).Source_Events (Event_Nr));

   -------------------------------------------------------------------------

   function Get_Target_Event
     (Subject_Id : Skp.Subject_Id_Type;
      Event_Nr   : Event_Range)
      return Event_Action_Type
   is (Subject_Events (Subject_ID).Target_Events (Event_Nr));

   -------------------------------------------------------------------------

   function Get_Trap
     (Subject_Id : Skp.Subject_Id_Type;
      Trap_Nr    : Trap_Range)
      return Event_Entry_Type
   is (Subject_Events (Subject_ID).Source_Traps (Trap_Nr));

end Skp.Events;
