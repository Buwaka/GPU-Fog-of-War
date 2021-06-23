using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System;
using UnityEngine;


namespace Algorithms
{
    public class MidPointCircle
    {
        public static void GetByteNibbles(out uint first, out uint second, uint Byte)
        {
            //not going to care about endian here, but it might be a problem on exotic hardware
            first = (Byte & 0x0000FFFF); //LSB
            second = (Byte & 0xFFFF0000) >> 16; //MSB
        }

        public static void SetByteNibbles(uint first, uint second, out byte Byte)
        {
            //not going to care about endian here, but it might be a problem on exotic hardware
            Byte = (byte)(first | (second << 16));
        }

        //c# equivalent of inline keyword
        //https://docs.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.methodimploptions?redirectedfrom=MSDN&view=net-5.0
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void SetValue(int x, int y, int width, byte value, byte[] outData)
        {
            int target = y * width + x;
            if (x >= 0 && target >= 0 && target < outData.GetUpperBound(0))
            {
                //clean cell
                if (value == 0)
                {
                    // remove one from count
                    uint data = (uint)outData[target];
                    uint tempValue;
                    uint count;

                    GetByteNibbles(out tempValue, out count, data);

                    count = Math.Max(count - 1, 0);

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
        private static void DrawHorizontalLine(int a, int x, int y, int width, byte value, byte[] outData)
        {
            for(int i = a; i < x; i++)
            {
                SetValue(i, y, width, value, outData);
            }
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DrawOctantsLines(int a, int b, int x, int y, int width, byte value, byte[] outData)
        {
            DrawHorizontalLine(a - x, a + x, b + y, width, value, outData);
            DrawHorizontalLine(a - x, a + x, b - y, width, value, outData);

            DrawHorizontalLine(a - y, a + y, b + x, width, value, outData);
            DrawHorizontalLine(a - y, a + y, b - x, width, value, outData);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static void DrawOctants(int a, int b, int x, int y, int width, byte value, byte[] outData)
        {
            SetValue(a + x, b + y, width, value, outData);
            SetValue(a - x, b + y, width, value, outData);
            SetValue(a + x, b - y, width, value, outData);
            SetValue(a - x, b - y, width, value, outData);
            SetValue(a + y, b + x, width, value, outData);
            SetValue(a - y, b + x, width, value, outData);
            SetValue(a + y, b - x, width, value, outData);
            SetValue(a - y, b - x, width, value, outData);
        }

        public static void DrawCircle(Vector3 pos, float range, int GridSize, float CellSize, byte value, byte[] outData)
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
            int b = Mathf.RoundToInt(pos.z / CellSize);


            DrawOctantsLines(a, b, x, y, GridSize, value, outData);

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

                DrawOctantsLines(a, b, x, y, GridSize, value, outData);
            }
        }

        public static void DrawLineWrapper(int a, int b, int x, int y, int width, byte value, byte[] outData)
        {
            DrawHorizontalLine(a - x, a + x, b + y, width, value, outData);
            if (y != 0)
                DrawHorizontalLine(a - x, a + x, b - y, width, value, outData);
        }

        //varriation that doesn't print duplicate lines
        public static void DrawCircle2(Vector3 pos, float range, int GridSize, float CellSize, byte value, byte[] outData)
        {
            int radius = Mathf.RoundToInt(range / CellSize);
            int error = -radius;

            int x = radius;
            int y = 0;

            //center of the circle
            //x
            int a = Mathf.RoundToInt(pos.x / CellSize);
            //y
            int b = Mathf.RoundToInt(pos.z / CellSize);

            while (x >= y)
            {
                int lastY = y;

                error += y;
                ++y;
                error += y;

                DrawLineWrapper(a, b, x, lastY, GridSize, value, outData);

                if (error >= 0)
                {
                    if (x != lastY)
                        DrawLineWrapper(a, b, lastY, x, GridSize, value, outData);

                    error -= x;
                    --x;
                    error -= x;
                }
            }
        }

        //clean outer edges of the circle
        public static void CleanOuterCircle(Vector3 pos, float range, int GridSize, float CellSize, byte value, byte[] outData)
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
            int b = Mathf.RoundToInt(pos.z / CellSize);


            DrawOctants(a, b, x, y, GridSize, value, outData);

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

                DrawOctants(a, b, x, y, GridSize, value, outData);
            }
        }
    }
}