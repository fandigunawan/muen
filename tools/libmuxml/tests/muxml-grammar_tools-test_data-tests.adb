--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Muxml.Grammar_Tools.Test_Data.

with AUnit.Assertions; use AUnit.Assertions;
with System.Assertions;

--  begin read only
--  id:2.2/00/
--
--  This section can be used to add with clauses if necessary.
--
--  end read only
with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO;
with Ada.Exceptions;
with Ada.Text_IO;
with Ada.Text_IO.Text_Streams;
with Ada.Directories;

with Test_Utils;

with DOM.Core.Nodes;
with DOM.Core.Elements;
with DOM.Core.Documents;

with Muxml.system_src_schema;
with Muxml.Utils;
with McKae.XML.XPath.XIA;

--  begin read only
--  end read only
package body Muxml.Grammar_Tools.Test_Data.Tests is

--  begin read only
--  id:2.2/01/
--
--  This section can be used to add global variables and other elements.
--
--  end read only

   -- open the given file and return its content as string
   function File_To_String (File_Name : String) return String
   is
      File         : Ada.Text_IO.File_Type;
      File_Content : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Ada.Text_IO.Open (File => File,
                        Mode => Ada.Text_IO.In_File,
                        Name => File_Name);
      loop
         exit when Ada.Text_IO.End_Of_File (File => File);
         File_Content := File_Content
            & Ada.Text_IO.Unbounded_IO.Get_Line (File => File);
      end loop;
      Ada.Text_IO.Close (File => File);

      return To_String (File_Content);
   end File_To_String;

   -- Muxml.Write omits namespace declarations as an attribute of schema.
   -- This functions includes them.
   procedure Write_XML_With_Namespace (Data : Muxml.XML_Data_Type; File : String)
   is
      use Ada.Text_IO;
      use Ada.Text_IO.Text_Streams;

      --Output_File : File_Type;
      Schema_Node : DOM.Core.Node;
   begin
      -- add attribute for namespace declaration by hand
      Schema_Node := DOM.Core.Documents.Get_Element (Doc => Data.Doc);
      DOM.Core.Elements.Set_Attribute
         (Elem  => Schema_Node,
          Name  => "xmlns:" & DOM.Core.Nodes.Prefix (N => Schema_Node),
          Value => DOM.Core.Nodes.Namespace_URI (N => Schema_Node));

      Muxml.Write (Data => Data,
                   Kind => Muxml.None,
                   File => File);
   end Write_XML_With_Namespace;
--  begin read only
--  end read only

--  begin read only
   procedure Test_Get_Insert_Index (Gnattest_T : in out Test);
   procedure Test_Get_Insert_Index_dcc60e (Gnattest_T : in out Test) renames Test_Get_Insert_Index;
--  id:2.2/dcc60eded3c68908/Get_Insert_Index/1/0/
   procedure Test_Get_Insert_Index (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      Ancestors, Siblings :  String_Vector.Vector;

      procedure Assert_Makro (Tagname : String; Result : Insert_Query_Result_Type)
      is
      begin
         Assert (Condition => Result = Get_Insert_Index
                    (Ancestors => Ancestors,
                     New_Child => Tagname,
                     Siblings  => Siblings),
                 Message   => "Index mismatch: "
                    & Get_Insert_Index
                    (Ancestors => Ancestors,
                     New_Child => Tagname,
                     Siblings  => Siblings)'Image);
      end Assert_Makro;

      procedure Positive_Test
      is
      begin
         -- systemType : [config, configType], [hardware, hardwareType], [platform, platformType],
         -- [memory, memRegionsType], [deviceDomains, deviceDomainsType], [events, eventsType],
         -- [channels, channelsType], [components, componentsType],
         -- [subjects, subjectsType], [scheduling, schedulingType]

         -- subjectType: [vcpu, vcpuType], [bootparams, string], [memory, memoryRefsType],
         -- [devices, devicesRefType], [events, subjectEventsType],
         -- [channels, channelReferencesType], [monitor, monitorType],
         -- [component, componentReferenceType], [sibling, namedRefType]

         -- memRegionsType : [memory, memoryType]
         -- memoryType : [file, fileContentType], [fill, fillContentType],
         -- [hash, hash256Type], [hashRef, hashRefType]

         Ancestors.Clear;
         Siblings.Clear;

         Ancestors.Append ("subject");
         Ancestors.Append ("subjects");
         Ancestors.Append ("system");
         Assert_Makro (Tagname => "component", Result => 0);

         Siblings.Append ("vcpu");
         Assert_Makro (Tagname => "vcpu", Result => 1);

         Siblings.Append ("vcpu");
         Siblings.Append ("memory");
         Siblings.Append ("channels");
         Assert_Makro (Tagname => "vcpu", Result => 2);
         Assert_Makro (Tagname => "bootparams", Result => 2);
         Assert_Makro (Tagname => "component", Result => 4);

         Siblings.Append ("channels");
         Siblings.Append ("channels");
         Assert_Makro (Tagname => "channels", Result => 6);
         Assert_Makro (Tagname => "vcpu", Result => 2);

         Ancestors.Clear;
         Siblings.Clear;
         Ancestors.Append ("memory");
         Ancestors.Append ("memory");
         Ancestors.Append ("system");
         Siblings.Append ("file");
         Siblings.Append ("hash");
         Assert_Makro (Tagname => "fill", Result => 1);
      end Positive_Test;

      procedure No_Insertion_Possible
      is
      begin
         Ancestors.Clear;
         Siblings.Clear;

         Ancestors.Append ("subject");
         Ancestors.Append ("subjects");
         Ancestors.Append ("system");
         Assert_Makro (Tagname => "memoryBlock", Result => No_Legal_Index);
      end No_Insertion_Possible;

      procedure Index_Not_Unique
      is
      begin
         Ancestors.Clear;
         Siblings.Clear;

         Ancestors.Append ("memory");
         Siblings.Append ("memory");
         Siblings.Append ("memory");
         Assert_Makro (Tagname => "memory", Result => No_Unique_Index);
      end Index_Not_Unique;

      -- This test targets the fallback mechanism of Get_Parent_Type
      -- in case the type resolution is not possible.
      procedure Fallback_Parent_Type
      is
         Schema_Type_Resolution_Problem : constant String
           := "<xs:schema xmlns:xs=""http://www.w3.org/2001/XMLSchema"">"
             & " <xs:complexType name=""groupType"">"
             & "  <xs:sequence>"
             & "   <xs:element name=""group"" type=""subgroupType""/>"
             & "   <xs:element name=""groupname"" type=""xs:string""/>"
             & "  </xs:sequence>"
             & " </xs:complexType>"
             & " <xs:complexType name=""subgroupType"">"
             & "  <xs:sequence>"
             & "   <xs:element name=""membername"" type=""xs:string""/>"
             & "   <xs:element name=""group"" type=""subgroupType""/>"
             & "  </xs:sequence>"
             & " </xs:complexType>"
             & " <xs:element name=""group"" type=""groupType""/>"
             & "</xs:schema>";
      begin
         Ancestors.Clear;
         Siblings.Clear;
         Init_Order_Information (Schema_XML_Data => Schema_Type_Resolution_Problem);

         Ancestors.Append ("group");
         Ancestors.Append ("group");
         Ancestors.Append ("group");
         Siblings.Append ("membername");

         Assert_Makro (Tagname => "group", Result => 1);
      end Fallback_Parent_Type;

   begin
      Positive_Test;

      No_Insertion_Possible;
      Index_Not_Unique;

      Fallback_Parent_Type;
--  begin read only
   end Test_Get_Insert_Index;
--  end read only


--  begin read only
   procedure Test_Filter_XML (Gnattest_T : in out Test);
   procedure Test_Filter_XML_9aa343 (Gnattest_T : in out Test) renames Test_Filter_XML;
--  id:2.2/9aa343ecc2f33278/Filter_XML/1/0/
   procedure Test_Filter_XML (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      --  Positive test: Add some nodes to a file, filter it and compare result
      --  to original file
      procedure Positive_Test
      is
         Output : constant String := "obj/output_format_src.xml";
         Data   : Muxml.XML_Data_Type;
      begin
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                   (File_Name => "data/default_schema.xsd"));
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/format_src.xml");
         declare
            Root_Node         : constant DOM.Core.Node
              := DOM.Core.Documents.Get_Element (Doc => Data.Doc);
            Insertion_Targets : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
              (N     => Root_Node,
               XPath => "/system | "
                 & "/system/components/component[@name='tau0'] | "
                 & "/system/components/component[@name='tau0']/depends | "
                 & "/system/components/component[@name='tau0']/channels/"
                 & "/array[@logical='input_arr'] | "
                 & "/system/memory/memory[@name='backup']");
         begin
            for I in 0 .. DOM.Core.Nodes.Length (List => Insertion_Targets) - 1 loop
               declare
                  Target  : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item (List  => Insertion_Targets,
                                            Index => I);
                  New_Node : DOM.Core.Node;
               begin
                  New_Node := DOM.Core.Documents.Create_Element
                    (Doc      => Data.Doc,
                     Tag_Name => "arbitraryName");
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => New_Node,
                     Name  => "name",
                     Value => "some_value");
                  New_Node := DOM.Core.Nodes.Append_Child
                    (N         => Target,
                     New_Child => New_Node);
               end;
            end loop;
         end;
         Filter_XML (XML_Data => Data);
         Muxml.Write (Data => Data,
                      Kind => Muxml.None,
                      File => Output);
         Assert (Condition => Test_Utils.Equal_Files
                 (Filename1 => "data/format_src.xml",
                  Filename2 => Output),
                 Message   => "Policy mismatch: " & Output);

         Ada.Directories.Delete_File (Name => Output);
      end Positive_Test;

      ----------------------------------------------------------------------

      --  Negatvie test: no initiation of Order_Info before filtering
      procedure No_Initiation
      is
         Data : Muxml.XML_Data_Type;
      begin
         Clear_Order_Info;
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/format_src.xml");
         Filter_XML (XML_Data => Data);
         Assert (Condition => False,
                 Message   => "Exception expected (missing init)");
      exception
         when E : Validation_Error =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                      = "Could not find root-node with tag 'system'"
                      & " in loaded schema information.",
                    Message   => "Exception message mismatch: "
                      & Ada.Exceptions.Exception_Message (X => E));
      end No_Initiation;
   begin
      Positive_Test;
      No_Initiation;

--  begin read only
   end Test_Filter_XML;
--  end read only


--  begin read only
   procedure Test_Init_Order_Information (Gnattest_T : in out Test);
   procedure Test_Init_Order_Information_0376e1 (Gnattest_T : in out Test) renames Test_Init_Order_Information;
--  id:2.2/0376e1ad8eb6f2b9/Init_Order_Information/1/0/
   procedure Test_Init_Order_Information (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);

      File         : Ada.Text_IO.File_Type;
      File_Content : Ada.Strings.Unbounded.Unbounded_String;

      procedure Positive_Test
      is
      begin
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => "data/default_schema.xsd"));

         Ada.Text_IO.Create (File => File,
                             Mode => Ada.Text_IO.Out_File,
                             Name => "obj/default_ordering_maps.txt");
         Ada.Text_IO.Unbounded_IO.Put_Line
            (File => File,
             Item => To_Unbounded_String (To_String (OI => Order_Info)));
         Ada.Text_IO.Close (File => File);

         Assert (Condition => Test_Utils.Equal_Files
                    (Filename1 => "data/default_ordering_maps.txt",
                     Filename2 => "obj/default_ordering_maps.txt"),
                 Message   => "Mismatch of Order_Info");
      end Positive_Test;

      procedure Same_Name_Different_Type
      is
         Data   : Muxml.XML_Data_Type;
         Node, Node_New : DOM.Core.Node;
         Tmp_Filename : constant String
            := "obj/tmp_file.txt";
      begin
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/default_schema.xsd");

         -- clone the "subject" element within subjects and change the type of
         -- the second element
         Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='subjectsType']/xs:sequence"
                & "/xs:element[@name='subject']");
         Node_New := DOM.Core.Nodes.Clone_Node (N    => Node,
                                                Deep => True);
         Node_New := DOM.Core.Nodes.Append_Child
            (N         => DOM.Core.Nodes.Parent_Node (N => Node),
             New_Child => Node_New);
         DOM.Core.Elements.Set_Attribute
            (Elem  => Node_New,
             Name  => "type",
             Value => "subjectType2");

         -- insert a definition for subjectType2
         Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='subjectsType']");
         Node_New := DOM.Core.Nodes.Clone_Node (N    => Node,
                                                Deep => True);
         Node_New := DOM.Core.Nodes.Append_Child
            (N         => DOM.Core.Nodes.Parent_Node (N => Node),
             New_Child => Node_New);
         DOM.Core.Elements.Set_Attribute (Elem  => Node_New,
                        Name  => "name",
                        Value => "subjectType2");

         -- XMLAda does not provide a way to convert a DOM-tree to a string.
         -- Hence, we have to write it to a file and read it again.
         Write_XML_With_Namespace (Data => Data,
                                   File => Tmp_Filename);
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Node_Names for Key 'subjectType2' of Order_Info "
                       & "contain entry 'subject' at least twice. "
                       & "Name must be unique within one type",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Same_Name_Different_Type;

      procedure Cyclic_Group_Reference
      is
      begin
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => "data/cyclic_group_references.xsd"));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Found cyclic inclusion of elements within one type. "
                       & "The cycle is: xs:group name='sourceEventActionsGroup'"
                       & "/xs:choice/xs:group/xs:group name='group2'/xs:choice"
                       & "/xs:group/xs:group name='sourceEventActions",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Cyclic_Group_Reference;

      procedure More_Than_One_Namespace
      is
         Data   : Muxml.XML_Data_Type;
         Schema_Node : DOM.Core.Node;
         Tmp_Filename : constant String
            := "obj/tmp_file.txt";
      begin
         Muxml.Parse
            (Data => Data,
             Kind => Muxml.None,
             File => "data/default_schema.xsd");
         -- add attribute for namespace declaration by hand
         Schema_Node := DOM.Core.Documents.Get_Element (Doc => Data.Doc);
         DOM.Core.Elements.Set_Attribute
            (Elem  => Schema_Node,
             Name  => "xmlns:" & DOM.Core.Nodes.Prefix (N => Schema_Node),
             Value => DOM.Core.Nodes.Namespace_URI (N => Schema_Node));
         DOM.Core.Elements.Set_Attribute
            (Elem  => Schema_Node,
             Name  => "xmlns:test",
             Value => "http://www.test.test");
         Muxml.Write (Data => Data,
                      Kind => Muxml.None,
                      File => Tmp_Filename);

         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Schema declares multiple namespaces.",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end More_Than_One_Namespace;


      procedure Element_Without_Type_Attribute
      is
         use type DOM.Core.Node;

         Data                        : Muxml.XML_Data_Type;
         Element_Node, Type_Def_Node : DOM.Core.Node;
         Tmp_Filename                : constant String
                                     := "obj/element_no_type_attribute.xsd";
      begin
         --  Move the type definition to make an 'inline' definition.
         Muxml.Parse
            (Data => Data,
             Kind => Muxml.None,
             File => "data/default_schema.xsd");
         Element_Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='eventsType']"
                &  "/xs:sequence/xs:element[@name='event']");
         Type_Def_Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='eventType']");
         Assert (Condition => Element_Node /= null and Type_Def_Node /= null,
                 Message   => "Could not find elements to modify for new test.");

         DOM.Core.Elements.Remove_Attribute
            (Elem => Element_Node,
             Name => "type");
         Type_Def_Node := DOM.Core.Nodes.Insert_Before
            (N         => Element_Node,
             New_Child => Type_Def_Node);
         Write_XML_With_Namespace
            (Data => Data,
             File => Tmp_Filename);

         Clear_Order_Info;
         Init_Order_Information
            (Schema_XML_Data => File_To_String
                (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Found element-node without 'name' or 'type' attribute.",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Element_Without_Type_Attribute;

      procedure Element_Of_Type_Any
      is
         Data   : Muxml.XML_Data_Type;
         Tmp_Filename : constant String
            := "obj/tmp_file.txt";
      begin
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/default_schema.xsd");

         Muxml.Utils.Set_Attribute
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='eventsType']"
                & "/xs:sequence/xs:element[@name='event']",
             Name  => "type",
             Value => "any");

         Write_XML_With_Namespace (Data => Data,
                                   File => Tmp_Filename);
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Schema contains elements with type 'any' or 'anyType'",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Element_Of_Type_Any;

      procedure Has_Redefine_Node
      is
         Data     : Muxml.XML_Data_Type;
         Node_New : DOM.Core.Node;
         Tmp_Filename : constant String
            := "obj/tmp_file.txt";
      begin
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/default_schema.xsd");
         Node_New := DOM.Core.Documents.Create_Element
            (Doc      => Data.Doc,
             Tag_Name => "redefine");
         Node_New := DOM.Core.Nodes.Append_Child
            (N         => DOM.Core.Documents.Get_Element (Doc => Data.Doc),
             New_Child => Node_New);
         Write_XML_With_Namespace (Data => Data,
                                   File => Tmp_Filename);

         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Schema contains elements named 'import', 'include', "
                       & "'redefine', 'example' or 'any'",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Has_Redefine_Node;

      procedure Element_With_SubstitutionGroup
      is
         Data         : Muxml.XML_Data_Type;
         Node         : DOM.Core.Node;
         Tmp_Filename : constant String
                      := "obj/tmp_file.txt";
      begin
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/default_schema.xsd");

         Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='eventsType']"
                & "/xs:sequence/xs:element[@name='event']");
         DOM.Core.Elements.Set_Attribute
            (Elem  => Node,
             Name  => "substitutionGroup",
             Value => "someGroup");

         Write_XML_With_Namespace (Data => Data,
                                   File => Tmp_Filename);
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Found element-node with 'substitutionGroup' attribute.",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end Element_With_SubstitutionGroup;

      procedure SubstitutionGroup_External_Attribute
      is
         Data           : Muxml.XML_Data_Type;
         Node, Node_New : DOM.Core.Node;
         Tmp_Filename   : constant String
                        := "obj/tmp_file.txt";
      begin
         Muxml.Parse
           (Data => Data,
            Kind => Muxml.None,
            File => "data/default_schema.xsd");

         Node := Muxml.Utils.Get_Element
            (Doc   => Data.Doc,
             XPath => "/xs:schema/xs:complexType[@name='eventsType']"
                & "/xs:sequence/xs:element[@name='event']");
         Node_New := DOM.Core.Documents.Create_Element
            (Doc      => Data.Doc,
             Tag_Name => "xs:attribute");
         Node_New := DOM.Core.Nodes.Append_Child
            (N         => Node,
             New_Child => Node_New);
         DOM.Core.Elements.Set_Attribute
            (Elem  => Node_New,
             Name  => "name",
             Value => "substitutionGroup");

         Write_XML_With_Namespace (Data => Data,
                                   File => Tmp_Filename);
         Clear_Order_Info;
         Init_Order_Information (Schema_XML_Data => File_To_String
                                    (File_Name => Tmp_Filename));
         Assert (Condition => False,
                 Message   => "Exception expected");
      exception
         when E : Not_Implemented =>
            Assert (Condition => Ada.Exceptions.Exception_Message (X => E)
                       = "Schema contains element with attribute"
                       & " 'substitutionGroup'",
                    Message   => "Exception message mismatch: "
                       & Ada.Exceptions.Exception_Message (X => E));
      end SubstitutionGroup_External_Attribute;
   begin
      Positive_Test;

      -- Fault tests
      -- these tests specifically test the functions that check if the
      -- assumptions required for the parsing to be correct, hold.
      Same_Name_Different_Type;
      Cyclic_Group_Reference;
      More_Than_One_Namespace;
      Element_Without_Type_Attribute;
      Element_Of_Type_Any;
      Has_Redefine_Node;
      Element_With_SubstitutionGroup;
      SubstitutionGroup_External_Attribute;

--  begin read only
   end Test_Init_Order_Information;
--  end read only


--  begin read only
   procedure Test_To_String (Gnattest_T : in out Test);
   procedure Test_To_String_4c0f3c (Gnattest_T : in out Test) renames Test_To_String;
--  id:2.2/4c0f3c81b96c42bd/To_String/1/0/
   procedure Test_To_String (Gnattest_T : in out Test) is
--  end read only

      pragma Unreferenced (Gnattest_T);
   begin
      -- a non-trivial positive testcase is tested as part of the positive test
      -- of Init_Order_Information

      -- test case for empty Order_Info
      Clear_Order_Info;
      Assert (Condition => To_String (OI => Order_Info) =
                 "{"  & Ada.Characters.Latin_1.LF
                 & "}" & Ada.Characters.Latin_1.LF
                 & "{"  & Ada.Characters.Latin_1.LF
                 & "}",
              Message => "String mismatch: " & To_String (OI => Order_Info));
      Init_Order_Information (Schema_XML_Data => Muxml.system_src_schema.Data);

--  begin read only
   end Test_To_String;
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
end Muxml.Grammar_Tools.Test_Data.Tests;
