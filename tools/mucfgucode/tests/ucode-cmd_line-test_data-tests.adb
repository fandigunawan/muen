--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Ucode.Cmd_Line.Test_Data.

with AUnit.Assertions; use AUnit.Assertions;
with System.Assertions;

--  begin read only
--  id:2.2/00/
--
--  This section can be used to add with clauses if necessary.
--
--  end read only
with GNAT.Os_Lib;
--  begin read only
--  end read only
package body Ucode.Cmd_Line.Test_Data.Tests is

--  begin read only
--  id:2.2/01/
--
--  This section can be used to add global variables and other elements.
--
--  end read only

--  begin read only
--  end read only

--  begin read only
   procedure Test_Init (Gnattest_T : in out Test);
   procedure Test_Init_a69a58 (Gnattest_T : in out Test) renames Test_Init;
--  id:2.2/a69a5871ab5eef40/Init/1/0/
   procedure Test_Init (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      use type Ada.Strings.Unbounded.Unbounded_String;

      ----------------------------------------------------------------------

      procedure Invalid_Switch
      is
         Args        : aliased GNAT.OS_Lib.Argument_List
           := (1 => new String'("-x"));
         Test_Parser : GNAT.Command_Line.Opt_Parser;
      begin
         GNAT.Command_Line.Initialize_Option_Scan
           (Parser       => Test_Parser,
            Command_Line => Args'Unchecked_Access);

         Parser := Test_Parser;

         begin
            Init (Description => "Test run");
            for A in Args'Range loop
               GNAT.OS_Lib.Free (X => Args (A));
            end loop;
            Assert (Condition => False,
                    Message   => "Exception expected");

         exception
            when Invalid_Cmd_Line => null;
         end;

         for A in Args'Range loop
            GNAT.OS_Lib.Free (X => Args (A));
         end loop;
      end Invalid_Switch;

      ----------------------------------------------------------------------

      procedure Invalid_Parameter
      is
         Args : aliased GNAT.OS_Lib.Argument_List
           := (1 => new String'("-i"),
               2 => new String'("my_policy"),
               3 => new String'("-u"),
               4 => new String'("-o"),
               5 => new String'("my_out_path"));
         Test_Parser : GNAT.Command_Line.Opt_Parser;
      begin
         GNAT.Command_Line.Initialize_Option_Scan
           (Parser       => Test_Parser,
            Command_Line => Args'Unchecked_Access);

         Parser := Test_Parser;

         begin
            Init (Description => "Test run");
            for A in Args'Range loop
               GNAT.OS_Lib.Free (X => Args (A));
            end loop;
            Assert (Condition => False,
                    Message   => "Exception expected");

         exception
            when Invalid_Cmd_Line => null;
         end;

         for A in Args'Range loop
            GNAT.OS_Lib.Free (X => Args (A));
         end loop;
      end Invalid_Parameter;

      ----------------------------------------------------------------------

      procedure Positive_Test
      is
         Args : aliased GNAT.OS_Lib.Argument_List
           := (1 => new String'("-i"),
               2 => new String'("my_policy"),
               3 => new String'("-u"),
               4 => new String'("my_ucode_path"),
               5 => new String'("-o"),
               6 => new String'("my_out_path"));
         Test_Parser : GNAT.Command_Line.Opt_Parser;
      begin
         GNAT.Command_Line.Initialize_Option_Scan
           (Parser       => Test_Parser,
            Command_Line => Args'Unchecked_Access);

         Parser := Test_Parser;

         Init (Description => "Test run");

         for A in Args'Range loop
            GNAT.OS_Lib.Free (X => Args (A));
         end loop;

         Assert (Condition => Policy = "my_policy",
                 Message   => "Policy mismatch");
         Assert (Condition => Ucode_Dir = "my_ucode_path",
                 Message   => "Ucode dir mismatch");
         Assert (Condition => Output_Dir = "my_out_path",
                 Message   => "Output dir mismatch");
      end Positive_Test;
   begin
      Invalid_Switch;
      Invalid_Parameter;
      Positive_Test;
--  begin read only
   end Test_Init;
--  end read only


--  begin read only
   procedure Test_Get_Policy (Gnattest_T : in out Test);
   procedure Test_Get_Policy_aac0d6 (Gnattest_T : in out Test) renames Test_Get_Policy;
--  id:2.2/aac0d695aae58756/Get_Policy/1/0/
   procedure Test_Get_Policy (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      use Ada.Strings.Unbounded;

      Ref : constant Unbounded_String
        := To_Unbounded_String ("policy.xml");
   begin
      Policy := Ref;
      Assert (Condition => Get_Policy = Ref,
              Message   => "Policy mismatch");
--  begin read only
   end Test_Get_Policy;
--  end read only


--  begin read only
   procedure Test_Get_Ucode_Dir (Gnattest_T : in out Test);
   procedure Test_Get_Ucode_Dir_7c9989 (Gnattest_T : in out Test) renames Test_Get_Ucode_Dir;
--  id:2.2/7c9989d852956b29/Get_Ucode_Dir/1/0/
   procedure Test_Get_Ucode_Dir (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      use Ada.Strings.Unbounded;

      Ref : constant Unbounded_String
        := To_Unbounded_String ("policy.xml");
   begin
      Ucode_Dir := Ref;
      Assert (Condition => Get_Ucode_Dir = Ref,
              Message   => "Ucode dir mismatch");
--  begin read only
   end Test_Get_Ucode_Dir;
--  end read only


--  begin read only
   procedure Test_Get_Output_Dir (Gnattest_T : in out Test);
   procedure Test_Get_Output_Dir_c3e9c8 (Gnattest_T : in out Test) renames Test_Get_Output_Dir;
--  id:2.2/c3e9c87208c742d1/Get_Output_Dir/1/0/
   procedure Test_Get_Output_Dir (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      use Ada.Strings.Unbounded;

      Ref : constant Unbounded_String
        := To_Unbounded_String ("out_path");
   begin
      Output_Dir := Ref;
      Assert (Condition => Get_Output_Dir = Ref,
              Message   => "Output dir mismatch");
--  begin read only
   end Test_Get_Output_Dir;
--  end read only

--  begin read only
--  id:2.2/02/
--
--  This section can be used to add elaboration code for the global state.
--
begin
--  end read only
   null;
--  begin read only
--  end read only
end Ucode.Cmd_Line.Test_Data.Tests;
