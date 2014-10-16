--
--  Copyright (C) 2013  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Muchannel.Readers;
with Muchannel.Writer;

with Input;

package VT_Channels
is

   package VT_Channel is new Muchannel
     (Element_Type => Character,
      Elements     => 65472);

   package VT_Channel_Rdr is new VT_Channel.Readers (Protocol => 1);
   package VT_Channel_Wtr is new VT_Channel.Writer
     (Protocol     => 1,
      Null_Element => ASCII.NUL);

   package Key_Channel is new Muchannel
     (Element_Type => Input.Key_Event_Type,
      Elements     => 2016);
   package Key_Channel_Wtr is new Key_Channel.Writer
     (Protocol     => 2,
      Null_Element => Input.Null_Key_Event);

end VT_Channels;