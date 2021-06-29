using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System;
using UnityEngine;


namespace Algorithms
{
    public class MidPointCircle
    {
        //c# equivalent of inline keyword
        //https://docs.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.methodimploptions?redirectedfrom=MSDN&view=net-5.0
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void GetByteNibbles(out uint first, out uint second, uint Byte)
        {
            //Endian might be important on consoles or exotic hardware

            if (BitConverter.IsLittleEndian)
            {
                first =  (Byte & 0x0000000F); //LSB
                second = (Byte & 0x000000F0) >> 4; //MSB
            }
            else
            {
                first =  (Byte & 0xF0000000); //LSB
                second = (Byte & 0x0F000000) << 4; //MSB
            }
        }

        //c# equivalent of inline keyword
        //https://docs.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.methodimploptions?redirectedfrom=MSDN&view=net-5.0
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static void SetByteNibbles(uint first, uint second, out byte Byte)
        {
            Byte = (byte)(first | (second << 4));
        }

        //c# equivalent of inline keyword
        //https://docs.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.methodimploptions?redirectedfrom=MSDN&view=net-5.0
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void SetValue(int x, int y, int width, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            int target = y * width + x;

            if (target >= 0 && target < size)
            {
                //just set value and exit if we won't use nibble count hack
                if (!NibbleCountHack)
                {
                    outData[target] |= value;
                    return;
                }


                //clean cell
                if (value == 0)
                {
                    // remove one from count
                    uint data = (uint)outData[target];
                    uint tempValue;
                    uint count;

                    GetByteNibbles(out tempValue, out count, data);

                    count = count > 0 ? count - 1 : 0;

                    if (count == 0)
                    {
                        outData[target] = 0;
                    }
                    else
                    {
                        outData[target] = (byte)(count | tempValue);
                        SetByteNibbles(tempValue, count, out outData[target]);
                    }

                }
                //fill cell
                else
                {
                    uint data = (uint)outData[target];
                    uint tempValue;
                    uint count;

                    GetByteNibbles(out tempValue, out count, data);

                    count = Math.Min(count + 1, 15); //15 is max of 4 bits
                    tempValue |= value;

                    SetByteNibbles(tempValue, count, out outData[target]);

                    // we are storing the count of nearby units in the byte
                }
            }

        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DrawHorizontalLine(int a, int x, int y, int width, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            for(int i = a; i < Math.Min(x, width); i++)
            {
                SetValue(i, y, width, value, outData, size, NibbleCountHack);
            }
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DrawOctantsLines(int a, int b, int x, int y, int width, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            DrawHorizontalLine(a - x, a + x, b + y, width, value, outData, size, NibbleCountHack);
            DrawHorizontalLine(a - x, a + x, b - y, width, value, outData, size, NibbleCountHack);

            DrawHorizontalLine(a - y, a + y, b + x, width, value, outData, size, NibbleCountHack);
            DrawHorizontalLine(a - y, a + y, b - x, width, value, outData, size, NibbleCountHack);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DrawOctants(int a, int b, int x, int y, int width, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {

            SetValue(Math.Min(a + x, width), b + y, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a - x, width), b + y, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a + x, width), b - y, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a - x, width), b - y, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a + y, width), b + x, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a - y, width), b + x, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a + y, width), b - x, width, value, outData, size, NibbleCountHack);
            SetValue(Math.Min(a - y, width), b - x, width, value, outData, size, NibbleCountHack);
        }

        public static void DrawCircle(Vector2 pos, float range, int GridSize, float CellSize, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            //radius
            int r = Mathf.RoundToInt(range / CellSize);

            //draw x and y
            int x = r;
            int y = 0;

            //center of the circle
            //x
            int a = Mathf.RoundToInt(pos.x / CellSize);
            //y
            int b = Mathf.RoundToInt(pos.y / CellSize);


            DrawOctants(a, b, x, y, GridSize, value, outData, size, NibbleCountHack);

            // d is Bresenham magic
            // https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
            // is an approximation of a much more compliacted decision variable
            int d = 3 - (2 * r);

            while (x >= y)
            {
                y++;

                if (d > 0)
                {
                    x--;
                    d = d + ((2 * (x - y)) + 5);

                }
                else
                    d = d + ((4 * x) + 6);

                DrawOctants(a, b, x, y, GridSize, value, outData, size, NibbleCountHack);
            }
        }

        public static void DrawLineWrapper(int a, int b, int x, int y, int width, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            DrawHorizontalLine(a - x, a + x, b + y, width, value, outData, size, NibbleCountHack);
            if (y != 0)
                DrawHorizontalLine(a - x, a + x, b - y, width, value, outData, size, NibbleCountHack);
        }

        //varriation that doesn't print duplicate lines
        public static void DrawFullCircle(Vector2 pos, float range, int GridSize, float CellSize, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            int radius = Mathf.RoundToInt(range / CellSize);
            int error = -radius;

            int x = radius;
            int y = 0;

            //center of the circle
            //x
            int a = Mathf.RoundToInt(pos.x / CellSize);
            //y
            int b = Mathf.RoundToInt(pos.y / CellSize);

            while (x >= y)
            {
                int lastY = y;

                error += y;
                ++y;
                error += y;

                DrawLineWrapper(a, b, x, lastY, GridSize, value, outData, size, NibbleCountHack);

                if (error >= 0)
                {
                    if (x != lastY)
                        DrawLineWrapper(a, b, lastY, x, GridSize, value, outData, size, NibbleCountHack);

                    error -= x;
                    --x;
                    error -= x;
                }
            }
        }

        //clean outer edges of the circle
        public static void CleanOuterCircle(Vector2 pos, float range, int GridSize, float CellSize, byte value, byte[] outData, uint size, bool NibbleCountHack = false)
        {
            //radius
            int r = Mathf.RoundToInt(range / CellSize);

            //draw x and y
            int x = 0;
            int y = r;

            //center of the circle
            //x
            int a = Mathf.RoundToInt(pos.x / CellSize);
            //y
            int b = Mathf.RoundToInt(pos.y / CellSize);


            DrawOctants(a, b, x, y, GridSize, value, outData, size, NibbleCountHack);

            // d is Bresenham magic
            // https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
            // is an approximation of a much more compliacted decision variable
            int d = 3 - (2 * r);

            while (y >= x)
            {
                x++;

                if (d > 0)
                {
                    y--;
                    d = d + ((2 * (x - y)) + 5);
                }
                else
                    d = d + ((4 * x) + 6);

                DrawOctants(a, b, x, y, GridSize, value, outData, size, NibbleCountHack);
            }
        }
    }
}