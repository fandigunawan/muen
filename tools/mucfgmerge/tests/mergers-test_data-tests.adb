--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Mergers.Test_Data.

with AUnit.Assertions; use AUnit.Assertions;

package body Mergers.Test_Data.Tests is


--  begin read only
   procedure Test_Merge_Platform (Gnattest_T : in out Test);
   procedure Test_Merge_Platform_0cd3e6 (Gnattest_T : in out Test) renames Test_Merge_Platform;
--  id:2.2/0cd3e620cc856c4c/Merge_Platform/1/0/
   procedure Test_Merge_Platform (Gnattest_T : in out Test) is
   --  mergers.ads:25:4:Merge_Platform
--  end read only

      pragma Unreferenced (Gnattest_T);

      ----------------------------------------------------------------------

      procedure Merge_Platform
      is
         Filename     : constant String := "obj/merged_platform.xml";
         Ref_Filename : constant String := "data/merged_platform.ref.xml";

         Policy : Muxml.XML_Data_Type;
      begin
         Muxml.Parse (Data => Policy,
                      Kind => Muxml.Format_Src,
                      File => "data/test_policy.xml");
         Merge_Platform (Policy        => Policy,
                         Platform_File => "data/platform.xml");
         Muxml.Write (Data => Policy,
                      Kind => Muxml.Format_Src,
                      File => Filename);

         Assert (Condition => Test_Utils.Equal_Files
                 (Filename1 => Filename,
                  Filename2 => Ref_Filename),
                 Message   => "Policy mismatch");

         Ada.Directories.Delete_File (Name => Filename);
      end Merge_Platform;

      ----------------------------------------------------------------------

      procedure Merge_Platform_Null
      is
         Filename     : constant String := "obj/merged_platform_null.xml";
         Ref_Filename : constant String := "data/merged_platform_null.ref.xml";

         Policy : Muxml.XML_Data_Type;
      begin
         Muxml.Parse (Data => Policy,
                      Kind => Muxml.Format_Src,
                      File => "data/test_policy.xml");
         Muxml.Utils.Remove_Child
           (Node       => DOM.Core.Nodes.First_Child (N => Policy.Doc),
            Child_Name => "platform");

         Merge_Platform (Policy        => Policy,
                         Platform_File => "data/platform.xml");
         Muxml.Write (Data => Policy,
                      Kind => Muxml.Format_Src,
                      File => Filename);

         Assert (Condition => Test_Utils.Equal_Files
                 (Filename1 => Filename,
                  Filename2 => Ref_Filename),
                 Message   => "Policy mismatch");

         Ada.Directories.Delete_File (Name => Filename);
      end Merge_Platform_Null;
   begin
      Merge_Platform;
      Merge_Platform_Null;
--  begin read only
   end Test_Merge_Platform;
--  end read only

end Mergers.Test_Data.Tests;