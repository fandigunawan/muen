--
--  Copyright (C) 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

with Ada.Strings.Fixed;
with Ada.Containers.Ordered_Multisets;

with Interfaces;

with DOM.Core.Nodes;
with DOM.Core.Elements;
with DOM.Core.Documents;

with McKae.XML.XPath.XIA;

with Mulog;
with Muxml.Utils;

package body Expanders.Scheduling
is

   use type Interfaces.Unsigned_64;

   package Map_Of_Minor_Frame_Deadlines is new Ada.Containers.Ordered_Multisets
     (Element_Type => Interfaces.Unsigned_64);

   package MOMFD renames Map_Of_Minor_Frame_Deadlines;

   -------------------------------------------------------------------------

   procedure Add_Barrier_Configs (Data : in out Muxml.XML_Data_Type)
   is
      Major_Frames : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/scheduling/majorFrame");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Major_Frames) - 1 loop
         declare
            Major_Frame      : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Major_Frames,
                 Index => I);
            CPU_Nodes        : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Major_Frame,
                 XPath => "cpu");
            Barriers_Node    : constant DOM.Core.Node
              := DOM.Core.Documents.Create_Element
                (Doc      => Data.Doc,
                 Tag_Name => "barriers");
            Minor_Exit_Times : MOMFD.Set;
         begin
            for J in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
               declare
                  CPU_Node      : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => CPU_Nodes,
                       Index => J);
                  Minor_Frames  : constant DOM.Core.Node_List
                    := McKae.XML.XPath.XIA.XPath_Query
                      (N     => CPU_Node,
                       XPath => "minorFrame");
                  Current_Ticks : Interfaces.Unsigned_64 := 0;
               begin
                  for K in 0 .. DOM.Core.Nodes.Length
                    (List => Minor_Frames) - 1
                  loop
                     declare
                        Minor_Frame : constant DOM.Core.Node
                          := DOM.Core.Nodes.Item
                            (List  => Minor_Frames,
                             Index => K);
                        Minor_Ticks : constant Interfaces.Unsigned_64
                          := Interfaces.Unsigned_64'Value
                            (DOM.Core.Elements.Get_Attribute
                               (Elem => Minor_Frame,
                                Name => "ticks"));
                     begin
                        Current_Ticks := Current_Ticks + Minor_Ticks;
                        Minor_Exit_Times.Insert (New_Item => Current_Ticks);
                     end;
                  end loop;
               end;
            end loop;

            declare
               Cur_Ticks        : Interfaces.Unsigned_64 := 0;
               Cur_Barrier_Idx  : Positive               := 1;
               Cur_Barrier_Size : Positive               := 1;
               Pos              : MOMFD.Cursor
                 := MOMFD.First (Container => Minor_Exit_Times);
            begin
               while MOMFD.Has_Element (Position => Pos) loop
                  declare
                     Cur_Deadline : constant Interfaces.Unsigned_64
                       := MOMFD.Element (Position => Pos);
                  begin
                     if Cur_Deadline = Cur_Ticks then
                        Cur_Barrier_Size := Cur_Barrier_Size + 1;
                     elsif Cur_Barrier_Size > 1 then
                        declare
                           Size_Str : constant String
                             := Ada.Strings.Fixed.Trim
                               (Source => Cur_Barrier_Size'Img,
                                Side   => Ada.Strings.Left);
                           Barrier_Node : constant DOM.Core.Node
                             := DOM.Core.Documents.Create_Element
                               (Doc      => Data.Doc,
                                Tag_Name => "barrier");
                        begin
                           Mulog.Log
                             (Msg => "Adding barrier to major frame" & I'Img
                              & ": size " & Size_Str
                              & ", ticks" & Cur_Ticks'Img);
                           DOM.Core.Elements.Set_Attribute
                             (Elem  => Barrier_Node,
                              Name  => "size",
                              Value => Size_Str);
                           Muxml.Utils.Append_Child
                             (Node      => Barriers_Node,
                              New_Child => Barrier_Node);
                        end;
                        Cur_Barrier_Idx  := Cur_Barrier_Idx + 1;
                        Cur_Barrier_Size := 1;
                     end if;

                     Cur_Ticks := Cur_Deadline;
                     Pos       := MOMFD.Next (Position => Pos);
                  end;
               end loop;
            end;
            Muxml.Utils.Append_Child
              (Node      => Major_Frame,
               New_Child => Barriers_Node);
         end;
      end loop;
   end Add_Barrier_Configs;

end Expanders.Scheduling;
